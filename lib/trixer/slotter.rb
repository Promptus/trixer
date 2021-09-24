module Trixer
  class Slotter

    Booking = Struct.new(:id, :slot, :duration, :amount, :places, keyword_init: true)
    Place = Struct.new(:id, :capacity, keyword_init: true)
    
    # for example [64..88] => 16:00 - 22:00
    attr_reader :slots
    
    # maximum capacity per slot
    attr_reader :total_slotcapacity

    # occupied places per slot
    # slot => [t1, t3]
    attr_reader :occupied_places_index

    attr_reader :free_capacity_index

    # returns all bookings as internal structs for the given date
    attr_reader :booking_index

    # returns all open places as internal structs for the given date
    # they should be sorted by capacity and number
    attr_reader :place_index
    attr_reader :links

    def initialize(slots:, places:, links:)
      @slots = slots
      # fill missing links with empty array
      @links = places.inject(links || {}) { |h,place| h[place.id] ? h : h.merge(place.id => []) }
      @total_slotcapacity ||= places.sum(&:capacity)
      @place_index = places.inject({}) { |h, place| h.merge(place.id => place) }
      @occupied_places_index = slots.inject({}) { |h, slot| h.merge(slot => Set.new) }
      @free_capacity_index = slots.inject({}) { |h, slot| h.merge(slot => @total_slotcapacity) }
      @booking_index = {}
    end

    # this index holds all combinations for each capacity
    # hash: capacity => [[t1], [t2], [t1, t2]]
    def capacity_index
      return @capacity_index if @capacity_index

      @capacity_index = {}
      place_index.values.each do |place|
        @capacity_index[place.capacity] ||= []
        @capacity_index[place.capacity] << Set.new([place.id])
      end
      Trixer::Combinator.combinations(adjacency_list: links, objects: place_index.values.map(&:id)).each do |comb|
        comb_capacity = comb.inject(0) { |sum, place_id| sum += place_index[place_id].capacity }
        @capacity_index[comb_capacity] ||= []
        @capacity_index[comb_capacity] << Set.new(comb)
      end
      # sort from smaller combinations to bigger combinations 
      @capacity_index.each do |capacity, comb|
        @capacity_index[capacity].sort! { |c1, c2| c1.size <=> c2.size }
      end
      @capacity_index
    end

    def occupied_places_for(booking_slots:)
      occupied_places_index.values_at(*booking_slots).inject(Set.new) { |s,op| s | op }
    end

    def add_booking(booking:, place_restriction: nil)
      slot = booking.slot
      booking_slots = (slot..slot+booking.duration-1).to_a

      # there is some slot that would be booked which is not available
      # i.e. [1,2,3,5,6,7] & [3,4,5] = [3,5] => slot 4 is not available
      # or   [1,2,3,4] & [3,4,5] = [3,4] => slot 5 is not available
      return false if (slots & booking_slots).size != booking.duration

      # not enough free slots for this booking
      return false if free_capacity_index[slot] < booking.amount

      occupied_places = occupied_places_for(booking_slots: booking_slots)
      capacity_index.each do |capacity, combinations|
        next if capacity < booking.amount
        combinations.each do |comb|
          # skip place combination which contains an occupied place 
          next if (comb & occupied_places).any?

          # skip if combination does not include desired place
          next if place_restriction && place_restriction.any? && (comb & place_restriction).empty?
          
          # mark booking.duration-1 slots after the booked slot as occupied
          # for example: duration 4 (1 hour)
          # booking at 17:00:
          # - three slots after are blocked (17:15, 17:30, 17:45) because a new booking
          #   at that time would start while this booking is still active
          booking_slots.each do |s|
            @occupied_places_index[s] = @occupied_places_index[s] + comb
            @free_capacity_index[s] = total_slotcapacity - occupied_places_index[s].sum { |id| place_index[id].capacity }
            raise "free capacity is negative (#{@free_capacity_index[s]}) at slot #{s}" if @free_capacity_index[s] < 0
          end
          booking.places = comb
          @booking_index[booking.id] = booking
          return true
        end
      end
      # booking does not fit into the given slot
      return false
    end
  end
end
