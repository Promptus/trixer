module Trixer
  class Slotter

    Booking = Struct.new(:id, :slot, :duration, :amount, :places, keyword_init: true)
    Place = Struct.new(:id, :capacity, :priority, :bookings, keyword_init: true)

    # for example [64..88] => 16:00 - 22:00
    attr_reader :slots
    attr_reader :blocked_slots
    attr_reader :gap_slots
    attr_reader :limit

    attr_reader :slot_limit
    attr_reader :total

    # maximum capacity per slot
    attr_reader :total_slotcapacity

    attr_reader :total_capacity
    attr_reader :booked_capacity
    attr_reader :max_capacity

    # occupied places per slot
    # slot => [t1, t3]
    attr_reader :occupied_places_index

    attr_reader :free_capacity_index

    attr_reader :amount_index

    attr_reader :booked_slots_index

    # returns all bookings as internal structs for the given date
    attr_reader :booking_index

    # returns all open places as internal structs for the given date
    # they should be sorted by capacity and number
    attr_reader :place_index
    attr_reader :links

    def initialize(slots:, places:, links:, limit: nil, slot_limit: nil, blocked_slots: [])
      @slots = slots
      @blocked_slots = Set.new(blocked_slots)
      @gap_slots = {}
      slots.each_with_index { |slot, idx| @gap_slots[slot] = true if slots[idx-1] != slot-1 }

      @limit = limit
      @slot_limit = slot_limit
      # fill missing links with empty array
      @links = places.inject(links || {}) { |h,place| h[place.id] ? h : h.merge(place.id => []) }
      @total_slotcapacity ||= places.sum(&:capacity)
      @total_capacity = @total_slotcapacity * @slots.size
      @place_index = places.sort {|x,y| x.capacity <=> y.capacity }.inject({}) { |h, place| h.merge(place.id => place) }
      @occupied_places_index = slots.inject({}) { |h, slot| h.merge(slot => Set.new) }
      @amount_index = slots.inject({}) { |h, slot| h.merge(slot => 0) }
      @free_capacity_index = slots.inject({}) { |h, slot| h.merge(slot => total_slotcapacity) }
      @booked_slots_index = @place_index.keys.inject({}) { |h, place_id| h.merge(place_id => {}) }
      @max_capacity = capacity_index.keys.max.to_i
      @booking_index = {}
      @total = 0
      @booked_capacity = 0
    end

    def slot_blocked?(slot)
      @blocked_slots.include?(slot)
    end

    def slot_bookable?(slot:, duration:)
      return false if slot_blocked?(slot)

      booking_slots = (slot..slot+duration-1).to_a
      return false if (slots & booking_slots).size != duration

      true
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
        @capacity_index[capacity].sort! do |c1, c2|
          if c1.size == c2.size
            links1 = c1.inject(0) { |sum, place_id| sum += links[place_id].size }
            links2 = c2.inject(0) { |sum, place_id| sum += links[place_id].size }
            if links1 == links2
              # same amount of links: sort by priority
              c1prio = c1.map { |place_id| place_index[place_id].priority || 100_000 }.min
              c2prio = c2.map { |place_id| place_index[place_id].priority || 100_000 }.min
              c1prio <=> c2prio
            else
              # prioritize cominations with less links
              links1 <=> links2
            end
          else
            c1.size <=> c2.size
          end
        end
      end
      @capacity_index
    end

    def max_capacity_for(place_id:)
      capacity_index.reverse_each do |cap, combs|
        return cap if combs.any? { |comb| comb.include?(place_id) }
      end
      place_index[place_id].capacity
    end

    def occupied_places_for(booking_slots:)
      occupied_places_index.values_at(*booking_slots).inject(Set.new) { |s,op| s | op }
    end

    def booking_slots(booking:)
      slot = booking.slot
      return [] if !slot.is_a?(Integer) || slot_blocked?(slot)

      (slot..slot+booking.duration-1).to_a
    end

    def add_booking(booking:, place_restriction: nil, dry_run: false, check_limits: true)
      return :invalid_capacity if !booking.amount.is_a?(Integer) || booking.amount > max_capacity

      booking_slots = booking_slots(booking: booking)

      # there is some slot that would be booked which is not available
      # i.e. [1,2,3,5,6,7] & [3,4,5] = [3,5] => slot 4 is not available
      # or   [1,2,3,4] & [3,4,5] = [3,4] => slot 5 is not available
      return :slot_unavailable if (slots & booking_slots).size != booking.duration

      # total limit reached
      return :total_limit_reached if check_limits && limit && (total + booking.amount > limit)

      slot = booking.slot

      # slot limit reached
      return :slot_limit_reached if check_limits && slot_limit && (@amount_index[slot] + booking.amount > slot_limit)

      # not enough free slots for this booking
      booking_slots.each do |bslot|
        return :out_of_capacity if free_capacity_index[bslot] < booking.amount
      end

      occupied_places = occupied_places_for(booking_slots: booking_slots)
      capacity_index.each do |capacity, combinations|
        next if capacity < booking.amount
        combinations.each do |comb|
          # skip place combination which contains an occupied place
          next if (comb & occupied_places).any?

          # skip if combination does not include desired place
          next if place_restriction && place_restriction.any? && (comb & place_restriction).empty?

          # don't add booking, just inform that it fits
          return true if dry_run

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
          comb.each do |place_id|
            @place_index[place_id].bookings ||= []
            @place_index[place_id].bookings << booking
            booking_slots.each do |s|
              @booked_slots_index[place_id][s] = booking
            end
          end
          @amount_index[slot] += booking.amount
          @booking_index[booking.id] = booking
          @booked_capacity += booking.duration * booking.amount
          @total += booking.amount
          @place_slot_data_index = nil
          return true
        end
      end
      # booking does not fit into the given slot
      return :no_combination_found
    end

    def open_slots(around_slot:, amount:, duration:, result_limit: nil, check_limits: true, place_restriction: nil)
      return [] if amount > max_capacity
      return [] if check_limits && slot_limit && amount > slot_limit
      return [] if check_limits && limit && amount > limit

      found_slots = []
      slots.sort { |x,y| (around_slot-x).abs <=> (around_slot-y).abs }.each do |slot|
        booking = Slotter::Booking.new(slot: slot, amount: amount, duration: duration)
        if add_booking(booking: booking, dry_run: true, check_limits: check_limits, place_restriction: place_restriction) == true
          found_slots << slot
        end
        break if result_limit && found_slots.size >= result_limit
      end
      found_slots
    end

    def booked_ratio
      return 0.0 if total_capacity.zero?
      booked_capacity/total_capacity.to_f
    end

    def slot_distances
      @slot_distances = {}
      @place_index.each do |place_id, place|
        @slot_distances[place_id] = slots.reverse.each_with_index
      end
    end

    def free_amount_at(slot:)
      slot_free = slot_limit ? [0, slot_limit - amount_index[slot]].max : 999_999
      total_free = limit ? [0, limit - total].max : 999_999
      [total_free, slot_free, free_capacity_index[slot]].min
    end
  end
end
