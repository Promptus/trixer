# encoding: utf-8

include Trixer

RSpec.describe Slotter do
  let(:slots) { (64..73).to_a } # 16:00 - 18:15
  let(:limit) { nil }
  let(:slot_limit) { nil }
  let(:matrix) { Slotter.new(slots: slots, places: places, links: links, limit: limit, slot_limit: slot_limit) }
  
  let(:place1) { Slotter::Place.new(id: 1, capacity: 2) }
  let(:place2) { Slotter::Place.new(id: 2, capacity: 2) }
  let(:place3) { Slotter::Place.new(id: 3, capacity: 4) }
  let(:places) { [place1, place2, place3] }

  let(:links) { { 1 => [2], 2 => [3] } }

  context do
    let(:booking1) { Slotter::Booking.new(id: 1, duration: 4, amount: 4, slot: 66) } # 16:30 - 17:30
    let(:booking2) { Slotter::Booking.new(id: 2, duration: 4, amount: 2, slot: 64) } # 16:00 - 17:00
    let(:booking3) { Slotter::Booking.new(id: 3, duration: 4, amount: 2, slot: 68) } # 17:00 - 18:00
    let(:bookings) { [booking1, booking2, booking3] }

    before do
      bookings.each do |booking|
        matrix.add_booking(booking: booking)
      end
    end

    #     16:00       17:00       18:00
    #     64 65 66 67 68 69 70 71 72 73
    # m    6  6  2  2  2  2  6  6  8  8 free capacity
    # 1/2  2  2  2  2  3  3  3  3  +  +
    # 2/2  +  +  +  +  +  +  +  +  +  +
    # 3/4  +  +  1  1  1  1  +  +  +  +


    describe 'total_slotcapacity' do
      subject { matrix.total_slotcapacity }

      it { is_expected.to eql(8) }

      context do
        let(:places) do
          [
            Slotter::Place.new(id: 1, capacity: 2),
            Slotter::Place.new(id: 2, capacity: 2),
            Slotter::Place.new(id: 3, capacity: 4),
            Slotter::Place.new(id: 4, capacity: 6),
            Slotter::Place.new(id: 5, capacity: 8),
          ]
        end
        it { is_expected.to eql(22) }
      end
    end

    describe 'place_index' do
      subject { matrix.place_index }

      it { is_expected.to eql(1 => place1, 2 => place2, 3 => place3) }
    end

    describe 'booking_index' do
      subject { matrix.booking_index }

      it { is_expected.to eql(1 => booking1, 2 => booking2, 3 => booking3) }
    end

    describe 'capacity_index' do
      subject { matrix.capacity_index }

      it do
        is_expected.to eql(
          2 => [Set.new([1]), Set.new([2])],
          4 => [Set.new([3]), Set.new([1, 2])],
          6 => [Set.new([2, 3])],
          8 => [Set.new([1, 2, 3])]
        )
      end

    end

    describe 'occupied_places_index' do
      subject { matrix.occupied_places_index[slot] }

      let(:slot) { 64 }
      it { is_expected.to eql(Set.new([1])) }

      context do
        let(:slot) { 67 }
        it { is_expected.to eql(Set.new([1, 3])) }
      end

      context do
        let(:slot) { 68 }
        it { is_expected.to eql(Set.new([1, 3])) }
      end
    end

    describe 'free_capacity_index' do
      subject { matrix.free_capacity_index[slot] }

      let(:slot) { 64 }
      it { is_expected.to eql(6) }

      context do
        let(:slot) { 67 }
        it { is_expected.to eql(2) }
      end

      context do
        let(:slot) { 68 }
        it { is_expected.to eql(2) }
      end

      context do
        let(:slot) { 70 }
        it { is_expected.to eql(6) }
      end

      context do
        let(:slot) { 72 }
        it { is_expected.to eql(8) }
      end
    end
    describe 'add_booking' do
      let(:place_restriction) { nil }
      subject { matrix.add_booking(booking: booking, place_restriction: place_restriction) }
    
      context "adds booking to place 2" do
        let(:booking) { Slotter::Booking.new(id: 4, duration: 4, amount: 2, slot: 66) }
        it { is_expected.to be_truthy }
        it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([2])) }
        it { expect { subject }.to change { matrix.free_capacity_index[66] }.from(2).to(0) }
        it { expect { subject }.to change { matrix.occupied_places_index[66] }.from(Set.new([3,1])).to(Set.new([3,1,2])) }
        it { expect { subject }.to change { matrix.amount_index[66] }.from(4).to(6) }
        it { expect { subject }.to_not change { matrix.amount_index[67] } }

        context "slot limit reached" do
          let(:slot_limit) { 4 }
          it { is_expected.to be_falsey }
          it { expect { subject }.to_not change { booking.places } }
        end
      end
      
      context "adds booking to place 2 with capacity 1" do
        let(:booking) { Slotter::Booking.new(id: 4, duration: 4, amount: 1, slot: 66) }
        it { is_expected.to be_truthy }
        it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([2])) }
        it { expect { subject }.to change { matrix.free_capacity_index[66] }.from(2).to(0) }
        it { expect { subject }.to change { matrix.occupied_places_index[66] }.from(Set.new([3,1])).to(Set.new([3,1,2])) }
      end

      context "adds booking to place 2 with duration 6" do
        let(:booking) { Slotter::Booking.new(id: 4, duration: 6, amount: 2, slot: 66) }
        it { is_expected.to be_truthy }
        it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([2])) }
        it { expect { subject }.to change { matrix.free_capacity_index[66] }.from(2).to(0) }
        it { expect { subject }.to change { matrix.free_capacity_index[71] }.from(6).to(4) }
      end

      context "adds (4/2) at 64 to place 3" do
        let(:booking) { Slotter::Booking.new(id: 4, duration: 2, amount: 4, slot: 64) }
        it { is_expected.to be_truthy }
        it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([3])) }
        it { expect { subject }.to change { matrix.free_capacity_index[64] }.from(6).to(2) }
        it { expect { subject }.to change { matrix.free_capacity_index[65] }.from(6).to(2) }
      end

      context "not enough space for (4/3) at 64" do
        let(:booking) { Slotter::Booking.new(id: 4, duration: 3, amount: 4, slot: 64) }
        it { is_expected.to be_falsey }
        it { expect { subject }.to_not change { booking.places } }
      end

      context "adds (4/2) at 72 to place 3" do
        let(:booking) { Slotter::Booking.new(id: 4, duration: 2, amount: 4, slot: 72) }
        it { is_expected.to be_truthy }
        it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([3])) }
        it { expect { subject }.to change { matrix.free_capacity_index[72] }.from(8).to(4) }
        it { expect { subject }.to change { matrix.free_capacity_index[73] }.from(8).to(4) }
        it { expect { subject }.to change { matrix.amount_index[72] }.from(0).to(4) }
        it { expect { subject }.to_not change { matrix.amount_index[73] } }

        context "total limit reached" do
          let(:limit) { 10 }
          it { is_expected.to be_falsey }
          it { expect { subject }.to_not change { booking.places } }
        end
      end

      context "not enough space for (4/3) at 72" do
        let(:booking) { Slotter::Booking.new(id: 4, duration: 3, amount: 4, slot: 72) }
        it { is_expected.to be_falsey }
        it { expect { subject }.to_not change { booking.places } }
      end
  
      context "not enough free capacity" do
        let(:booking) { Slotter::Booking.new(id: 4, duration: 4, amount: 3, slot: 66) }
        it { is_expected.to be_falsey }
        it { expect { subject }.to_not change { booking.places } }
        it { expect { subject }.to_not change { matrix.free_capacity_index[66] } }
        it { expect { subject }.to_not change { matrix.occupied_places_index[66] } }
      end
  
      context "too close to closing time" do
        let(:booking) { Slotter::Booking.new(id: 4, duration: 4, amount: 2, slot: 71) }
        it { is_expected.to be_falsey }
        it { expect { subject }.to_not change { booking.places } }
        it { expect { subject }.to_not change { matrix.free_capacity_index[71] } }
        it { expect { subject }.to_not change { matrix.occupied_places_index[71] } }
      end

      context "adds (4/2) at 72 to place 1 and 2 if 3 is occupied" do
        let(:booking4) { Slotter::Booking.new(id: 4, duration: 4, amount: 4, slot: 70) }
        let(:bookings) { [booking1, booking2, booking3, booking4] }

        let(:booking) { Slotter::Booking.new(id: 5, duration: 2, amount: 4, slot: 72) }

        it { is_expected.to be_truthy }
        it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([1,2])) }
        it { expect { subject }.to change { matrix.free_capacity_index[72] }.from(4).to(0) }
        it { expect { subject }.to change { matrix.free_capacity_index[73] }.from(4).to(0) }
      end
    end
  end

  describe 'add_booking' do
    let(:place_restriction) { nil }
    subject { matrix.add_booking(booking: booking, place_restriction: place_restriction) }

    context "combined places" do
      let(:booking) { Slotter::Booking.new(id: 1, duration: 4, amount: 6, slot: 66) }

      it { is_expected.to be_truthy }
      it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([2,3])) }
      it { expect { subject }.to change { matrix.free_capacity_index[66] }.from(8).to(2) }
      it { expect { subject }.to_not change { matrix.free_capacity_index[64] } }
      it { expect { subject }.to change { matrix.occupied_places_index[66] }.from(Set.new).to(Set.new([2,3])) }
    end

    context "special place required" do
      let(:place_restriction) { [place2.id] }
      let(:booking) { Slotter::Booking.new(id: 1, duration: 4, amount: 2, slot: 66) }

      it { is_expected.to be_truthy }
      it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([2])) }
      it { expect { subject }.to change { matrix.free_capacity_index[66] }.from(8).to(6) }
      it { expect { subject }.to_not change { matrix.free_capacity_index[64] } }
      it { expect { subject }.to change { matrix.occupied_places_index[66] }.from(Set.new).to(Set.new([2])) }
    end
  end
end

# big matrix
RSpec.describe Slotter do
  let(:slots) { (56..80).to_a } # 14:00 - 20:00
  
  let(:places) do
    (1..100).map do |id|
      Slotter::Place.new(id: id, capacity: (id/33)*2+2)
    end
  end
  
  let(:links) do
    links = {}
    (1..50).each do |id|
      links[id] = [100-id]
    end
    links
  end
  
  let(:matrix) { Slotter.new(slots: slots, places: places, links: links) }

  describe 'total_slotcapacity' do
    subject { matrix.total_slotcapacity }

    it { is_expected.to eql(410) }
  end

  describe 'places' do
    subject { matrix.place_index.values.map(&:capacity).uniq }

    it { is_expected.to eql([2,4,6,8]) }
  end

  describe 'capacity_index' do
    subject { matrix.capacity_index[10] }

    it do
      is_expected.to eql([Set.new([1, 99]), Set.new([33, 67]), Set.new([34, 66])])
    end
  end

  context 'performance test' do
    
    it do
      puts "#{places.size} places"
      puts "#{links.size} links"
      t0 = Time.now
      (1..500).each do |id|
        matrix.add_booking(booking: Slotter::Booking.new(id: id, duration: [2,4,6].sample, amount: [2,4,6,8].sample, slot: slots.sample))
      end
      puts "added #{matrix.booking_index.values.size} bookings in #{(1000*(Time.now-t0)).round}ms"
    end

  end

end