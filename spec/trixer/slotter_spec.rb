# encoding: utf-8

include Trixer

RSpec.describe Slotter do
  let(:slots) { (64..73).to_a } # 16:00 - 18:15
  let(:matrix) { Slotter.new(slots: slots, places: places, links: links) }
  
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
      let(:place) { nil }
      subject { matrix.add_booking(booking: booking, place: place) }
    
      context "adds booking to place 2" do
        let(:booking) { Slotter::Booking.new(id: 4, duration: 4, amount: 2, slot: 66) }
        it { is_expected.to be_truthy }
        it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([2])) }
        it { expect { subject }.to change { matrix.free_capacity_index[66] }.from(2).to(0) }
        it { expect { subject }.to change { matrix.occupied_places_index[66] }.from(Set.new([3,1])).to(Set.new([3,1,2])) }
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
    let(:place) { nil }
    subject { matrix.add_booking(booking: booking, place: place) }

    context "combined places" do
      let(:booking) { Slotter::Booking.new(id: 1, duration: 4, amount: 6, slot: 66) }

      it { is_expected.to be_truthy }
      it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([2,3])) }
      it { expect { subject }.to change { matrix.free_capacity_index[66] }.from(8).to(2) }
      it { expect { subject }.to_not change { matrix.free_capacity_index[64] } }
      it { expect { subject }.to change { matrix.occupied_places_index[66] }.from(Set.new).to(Set.new([2,3])) }
    end

    context "special place required" do
      let(:place) { place2 }
      let(:booking) { Slotter::Booking.new(id: 1, duration: 4, amount: 2, slot: 66) }

      it { is_expected.to be_truthy }
      it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([2])) }
      it { expect { subject }.to change { matrix.free_capacity_index[66] }.from(8).to(6) }
      it { expect { subject }.to_not change { matrix.free_capacity_index[64] } }
      it { expect { subject }.to change { matrix.occupied_places_index[66] }.from(Set.new).to(Set.new([2])) }
    end
  end
end
