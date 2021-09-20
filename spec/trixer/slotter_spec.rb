# encoding: utf-8

include Trixer

RSpec.describe Slotter do
  let(:slots) { (64..73).to_a } # 16:00 - 18:15
  let(:slot_size) { 4 }
  let(:matrix) { Slotter.new(slots: slots, slot_size: slot_size, places: places, links: links, bookings: bookings) }
  
  let(:booking1) { Slotter::Booking.new(id: 1, capacity: 4, slot: 66) } # 16:30 - 17:30
  let(:booking2) { Slotter::Booking.new(id: 2, capacity: 2, slot: 64) } # 16:00 - 17:00
  let(:booking3) { Slotter::Booking.new(id: 3, capacity: 2, slot: 68) } # 17:00 - 18:00
  let(:bookings) { [booking1, booking2, booking3] }

  let(:table1) { Slotter::Place.new(id: 1, capacity: 2) }
  let(:table2) { Slotter::Place.new(id: 2, capacity: 2) }
  let(:table3) { Slotter::Place.new(id: 3, capacity: 4) }
  let(:places) { [table1, table2, table3] }

  let(:links) { { 1 => [2], 2 => [3] } }

  #     16:00       17:00       18:00
  #     64 65 66 67 68 69 70 71 72 73
  # m    2  2  2  2  2  2  2  2  8  8 free capacity
  # 1/2  2  2  2  2  3  3  3  3  +  +
  # 2/2  +  +  +  +  +  +  +  +  +  +
  # 3/4  -  -  1  1  1  1  +  +  +  +


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

  describe 'table_index' do
    subject { matrix.table_index }

    it { is_expected.to eql(1 => table1, 2 => table2, 3 => table3) }
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

  describe 'occupied_tables_index' do
    subject { matrix.occupied_tables_index[slot] }

    let(:slot) { 64 }
    it { is_expected.to eql(Set.new([1, 3])) }

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
    it { is_expected.to eql(2) }

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
    subject { matrix.add_booking(booking: booking) }

    # initial state
    #     16:00       17:00       18:00
    #     64 65 66 67 68 69 70 71 72 73
    # m    2  2  2  2  2  2  2  2  8  8 free capacity
    # 1/2  2  2  2  2  3  3  3  3  +  +
    # 2/2  +  +  +  +  +  +  +  +  +  +
    # 3/4  -  -  1  1  1  1  +  +  +  +

    context "adds booking to table 2" do
      let(:booking) { Slotter::Booking.new(id: 4, capacity: 2, slot: 66) }
      it { is_expected.to be_truthy }
      it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([2])) }
      it { expect { subject }.to change { matrix.free_capacity_index[66] }.from(2).to(0) }
      it { expect { subject }.to change { matrix.occupied_tables_index[66] }.from(Set.new([3,1])).to(Set.new([3,1,2])) }
    end
    
    context "adds booking to table 2 with capacity 1" do
      let(:booking) { Slotter::Booking.new(id: 4, capacity: 1, slot: 66) }
      it { is_expected.to be_truthy }
      it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([2])) }
      it { expect { subject }.to change { matrix.free_capacity_index[66] }.from(2).to(0) }
      it { expect { subject }.to change { matrix.occupied_tables_index[66] }.from(Set.new([3,1])).to(Set.new([3,1,2])) }
    end

    context "not enough free capacity" do
      let(:booking) { Slotter::Booking.new(id: 4, capacity: 3, slot: 66) }
      it { is_expected.to be_falsey }
      it { expect { subject }.to_not change { booking.places } }
      it { expect { subject }.to_not change { matrix.free_capacity_index[66] } }
      it { expect { subject }.to_not change { matrix.occupied_tables_index[66] } }
    end

    context "too close to closing time" do
      let(:booking) { Slotter::Booking.new(id: 4, capacity: 2, slot: 71) }
      it { is_expected.to be_falsey }
      it { expect { subject }.to_not change { booking.places } }
      it { expect { subject }.to_not change { matrix.free_capacity_index[71] } }
      it { expect { subject }.to_not change { matrix.occupied_tables_index[71] } }
    end

    context "combined places" do
      let(:bookings) { [] }
      let(:booking) { Slotter::Booking.new(id: 1, capacity: 6, slot: 66) }

      it { is_expected.to be_truthy }
      it { expect { subject }.to change { booking.places }.from(nil).to(Set.new([2,3])) }
      it { expect { subject }.to change { matrix.free_capacity_index[66] }.from(8).to(2) }
      it { expect { subject }.to change { matrix.free_capacity_index[64] }.from(8).to(2) }
      it { expect { subject }.to change { matrix.occupied_tables_index[66] }.from(Set.new).to(Set.new([2,3])) }
    end
  end
end
