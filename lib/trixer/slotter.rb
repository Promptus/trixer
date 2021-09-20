module Trixer
  class Slotter

    Booking = Struct.new(:id, :slot, :capacity, :places, keyword_init: true)
    Place = Struct.new(:id, :capacity, keyword_init: true)
    
    # for example [64..88] => 16:00 - 22:00
    attr_reader :slots
    # number of slots per booking, i.e. duration of booking
    attr_reader :slot_size
    
    # maximum capacity per slot
    attr_reader :total_slotcapacity

    # occupied places per slot
    # slot => [t1, t3]
    attr_reader :occupied_tables_index

    attr_reader :free_capacity_index

    # returns all bookings as internal structs for the given date
    attr_reader :bookings
    attr_reader :booking_index

    # returns all open places as internal structs for the given date
    # they should be sorted by capacity and number
    attr_reader :places
    attr_reader :table_index
    attr_reader :links

    def initialize(slots:, slot_size:, places:, links:, bookings:)
      @slots = slots
      @slot_size = slot_size
      @places = places
      # fill missing links with empty array
      @links = places.inject(links || {}) { |h,table| h[table.id] ? h : h.merge(table.id => []) }
      @total_slotcapacity ||= places.sum(&:capacity)
      @table_index = places.inject({}) { |h, table| h.merge(table.id => table) }
      @occupied_tables_index = slots.inject({}) { |h, slot| h.merge(slot => Set.new) }
      @free_capacity_index = slots.inject({}) { |h, slot| h.merge(slot => @total_slotcapacity) }
      @bookings = bookings
      @booking_index = bookings.inject({}) { |h, booking| h.merge(booking.id => booking) }
      @bookings.sort { |b1,b2| b2.capacity <=> b1.capacity }.each { |booking| add_booking(booking: booking) }
    end

    # hash: capacity => [[t1], [t2], [t1, t2]]
    def capacity_index
      return @capacity_index if @capacity_index

      @capacity_index = {}
      places.each do |table|
        @capacity_index[table.capacity] ||= []
        @capacity_index[table.capacity] << Set.new([table.id])
      end
      Trixer::Combinator.combinations(adjacency_list: links, objects: places.map(&:id)).each do |comb|
        comb_capacity = comb.inject(0) { |sum, table_id| sum += table_index[table_id].capacity }
        @capacity_index[comb_capacity] ||= []
        @capacity_index[comb_capacity] << Set.new(comb)
      end
      # sort from smaller combinations to bigger combinations 
      @capacity_index.each do |capacity, comb|
        @capacity_index[capacity].sort! { |c1, c2| c1.size <=> c2.size }
      end
      @capacity_index
    end

    def add_booking(booking:, place: nil)
      slot = booking.slot
      occupied_tables = occupied_tables_index[slot]
      # not enough free seats for this booking
      return false if free_capacity_index[slot] < booking.capacity

      capacity_index.each do |capacity, combinations|
        next if capacity < booking.capacity
        combinations.each do |comb|
          # skip table combination which contains an occupied table 
          next if (comb & occupied_tables).any?

          # mark slot_size-1 slots before and after the booked slot as occupied
          # for example: slot_size 4 (1 hour)
          # booking at 17:00:
          # - three slots before are blocked (16:15, 16:30, 16:45) because a new booking
          #   at that time would end after the start of this booking
          # - three slots after are blocked (17:15, 17:30, 17:45) because a new booking
          #   at that time would start while this booking is still active
          from_slot = slot-slot_size-1
          to_slot = slot+slot_size-1

          # the booking would end after the last slot
          next if @occupied_tables_index[to_slot].nil?
          
          (from_slot..to_slot).each do |s|
            next if @occupied_tables_index[s].nil?
            @occupied_tables_index[s] = @occupied_tables_index[s] + comb
            @free_capacity_index[s] = total_slotcapacity - occupied_tables_index[s].sum { |id| table_index[id].capacity }
            raise "free capacity is negative (#{@free_capacity_index[s]}) at slot #{s}" if @free_capacity_index[s] < 0
          end
          booking.places = comb
          return true
        end
      end
      # booking does not fit into the given slot
      return false
    end
  end
end
