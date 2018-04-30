require 'benchmark'

RSpec.describe Trixer::Combinator do
  
  let(:matrix) { [[0,1,1], [0,0,0], [0,0,0]] }

  describe '#groups_of_two' do
    subject { Trixer::Combinator.new(matrix: matrix).groups_of_two }

    it do
      is_expected.to eql(Set[Set[0,1], Set[0,2]])
    end

  end

  describe '#calculate' do
    let!(:combinator) { Trixer::Combinator.new(matrix: matrix) }
    subject { combinator.calculate }

    it do
      is_expected.to eql({ 2 => Set[Set[0,1],Set[0,2]], 3 => Set[Set[2,0,1]] })
    end

    context 'slightly bigger example' do
      let(:matrix) do
        [
          [0,1,0,0,1,0,0,0,0,0],
          [0,0,1,0,0,0,0,0,0,0],
          [0,0,0,1,0,0,0,0,0,0],
          [0,0,0,0,0,0,0,0,0,0],
          [0,0,0,0,0,0,0,0,0,0],
          [0,0,0,0,0,0,1,0,0,0],
          [0,0,0,0,0,0,0,0,0,0],
          [0,0,0,0,0,0,0,0,1,0],
          [0,0,0,0,0,0,0,0,0,0],
          [0,0,0,0,0,0,0,0,0,0],
        ]
      end
      it { expect(subject[2]).to eql(Set[Set[0,1],Set[0,4],Set[1,2],Set[2,3],Set[5,6],Set[7,8]]) }
      it { expect(subject[3]).to eql(Set[Set[4,0,1], Set[0,2,1], Set[1,3,2]]) }
      it { expect(subject[4]).to eql(Set[Set[4, 0, 2, 1], Set[0, 3, 2, 1]]) }
      it { expect(subject[5]).to eql(Set[Set[4, 0, 3, 2, 1]]) }
      it { expect(subject[6]).to eql(Set[]) }
    end

    context 'every table is connected to each other' do
      let(:matrix) do
        [
          [0,1,1,1,1,1,1,1,1,1],
          [0,0,1,1,1,1,1,1,1,1],
          [0,0,0,1,1,1,1,1,1,1],
          [0,0,0,0,1,1,1,1,1,1],
          [0,0,0,0,0,1,1,1,1,1],
          [0,0,0,0,0,0,1,1,1,1],
          [0,0,0,0,0,0,0,1,1,1],
          [0,0,0,0,0,0,0,0,1,1],
          [0,0,0,0,0,0,0,0,0,1],
          [0,0,0,0,0,0,0,0,0,0],
        ]
      end

      # 2*45 + 2*120 + 2*210 + 252 + 10 + 1 = 1013
      it { expect(subject[2].size).to eql(45) }
      it { expect(subject[3].size).to eql(120) }
      it { expect(subject[4].size).to eql(210) }
      it { expect(subject[5].size).to eql(252) }
      it { expect(subject[6].size).to eql(210) }
      it { expect(subject[7].size).to eql(120) }
      it { expect(subject[8].size).to eql(45) }
      it { expect(subject[9].size).to eql(10) }
      it { expect(subject[10].size).to eql(1) }
    end

    context 'Lake Side' do
      let(:matrix) do
        [# 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 0
          [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 1
          [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 2
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 3
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 4
          [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 5
          [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 6
          [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 7
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 8
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 9
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 10
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 11
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0], # 12
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0], # 13
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 14
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 15
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0], # 16
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], # 17
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], # 18
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0], # 19
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], # 20
          [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 21
        ]
      end

      it { expect(subject[2].size).to eql(14) }
      it { expect(subject[3].size).to eql(10) }
      it { expect(subject[4].size).to eql(6) }
      it { expect(subject[5].size).to eql(4) }
      it { expect(subject[6].size).to eql(2) }
      it { expect(subject[7].size).to eql(0) }
      it { expect(subject[21].size).to eql(0) }
    end
  end

  describe '::combinations' do
    let(:adjacency_list) do
      {
        '201' => ['202'],
        '202' => ['201', '203'],
        '203' => ['202', '204'],
        '204' => ['203', '205'],
        '205' => ['204', '206'],
        '206' => ['205'],
        '207' => [],
        '208' => ['209'],
        '209' => ['208', '210'],
        '210' => ['209'],
        '211' => [],
        '212' => [],
        '213' => ['214'],
        '214' => ['213', '215'],
        '215' => ['214'],
        '216' => [],
        '217' => ['218'],
        '218' => ['217', '219'],
        '219' => ['218', '220'],
        '220' => ['219', '221'],
        '221' => ['220', '222'],
        '222' => ['221'],
      }
    end
    subject { Trixer::Combinator.combinations(adjacency_list: adjacency_list) }

    it { expect(subject.size).to eql(36) }

    it { expect(subject[0]).to eq ['201', '202'] }
    it { expect(subject[1]).to eq ['202', '203'] }
    it { expect(subject[2]).to eq ['203', '204'] }
    it { expect(subject[3]).to eq ['204', '205'] }
    it { expect(subject[4]).to eq ['205', '206'] }
    it { expect(subject[5]).to eq ['208', '209'] }
    it { expect(subject[6]).to eq ['209', '210'] }

    it { expect(subject[7]).to eq ['213', '214'] }
    it { expect(subject[8]).to eq ['214', '215'] }
    it { expect(subject[9]).to eq ['217', '218'] }
    it { expect(subject[10]).to eq ['218', '219'] }
    it { expect(subject[11]).to eq ['219', '220'] }
    it { expect(subject[12]).to eq ['220', '221'] }
    it { expect(subject[13]).to eq ['221', '222'] }

    it { expect(subject[14]).to eq ['201', '202', '203'] }
    it { expect(subject[15]).to eq ['202', '203', '204'] }
    it { expect(subject[16]).to eq ['203', '204', '205'] }
    it { expect(subject[17]).to eq ['204', '205', '206'] }
    it { expect(subject[18]).to eq ['208', '209', '210'] }

    it { expect(subject[19]).to eq ['213', '214', '215'] }
    it { expect(subject[20]).to eq ['217', '218', '219'] }
    it { expect(subject[21]).to eq ['218', '219', '220'] }
    it { expect(subject[22]).to eq ['219', '220', '221'] }
    it { expect(subject[23]).to eq ['220', '221', '222'] }

    it { expect(subject[24]).to eq ['201', '202', '203', '204'] }
    it { expect(subject[25]).to eq ['202', '203', '204', '205'] }
    it { expect(subject[26]).to eq ['203', '204', '205', '206'] }

    it { expect(subject[27]).to eq ['217', '218', '219', '220'] }
    it { expect(subject[28]).to eq ['218', '219', '220', '221'] }
    it { expect(subject[29]).to eq ['219', '220', '221', '222'] }

    it { expect(subject[30]).to eq ['201', '202', '203', '204', '205'] }
    it { expect(subject[31]).to eq ['202', '203', '204', '205', '206'] }

    it { expect(subject[32]).to eq ['217', '218', '219', '220', '221'] }
    it { expect(subject[33]).to eq ['218', '219', '220', '221', '222'] }

    it { expect(subject[34]).to eq ['201', '202', '203', '204', '205', '206'] }
    it { expect(subject[35]).to eq ['217', '218', '219', '220', '221', '222'] }

    context "example 2" do
      let(:adjacency_list) do
        {
          '1' => ['3'],
          '2' => ['3'],
          '3' => ['1','2']
        }
      end

      it do
        is_expected.to eq [
          ['1', '3'],
          ['2', '3'],
          ['1', '3', '2']
        ]
      end
    end

    context "example 2" do
      let(:adjacency_list) do
        {
          '1' => ['3'],
          '2' => ['3'],
          '3' => ['1','2']
        }
      end

      it do
        is_expected.to eq [
          ['1', '3'],
          ['2', '3'],
          ['1', '3', '2']
        ]
      end
    end

    context "example 3" do
      let(:adjacency_list) do
        {
          '1' => ['2', '3', '4', '5', '6', '7', '8', '9'],
          '2' => ['1', '3', '4', '5', '6', '7', '8', '9'],
          '3' => ['1', '2', '4', '5', '6', '7', '8', '9'],
          '4' => ['1', '2', '3', '5', '6', '7', '8', '9'],
          '5' => ['1', '2', '3', '4'],
          '6' => ['1', '2', '3', '4'],
          '7' => ['1', '2', '3', '4'],
          '8' => ['1', '2', '3', '4'],
          '9' => ['1', '2', '3', '4']
        }
      end

      it { expect(subject.size).to eql(476) }
    end

    describe 'cross' do
      let(:adjacency_list) do
        {
          '1' => ['2', '3', '4'],
          '2' => ['1'],
          '3' => ['1'],
          '4' => ['1']
        }
      end
      
      it { expect(subject.size).to eql(7) }
      it { expect(subject[0]).to eql(%w(1 2)) }
      it { expect(subject[1]).to eql(%w(1 3)) }
      it { expect(subject[2]).to eql(%w(1 4)) }
  
      it { expect(subject[3]).to eql(%w(1 2 3)) }
      it { expect(subject[4]).to eql(%w(1 2 4)) }
      it { expect(subject[5]).to eql(%w(1 3 4)) }
      it { expect(subject[6]).to eql(%w(1 2 3 4)) }
    end
  end
end
