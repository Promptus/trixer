RSpec.describe Trixer::Combinator do
  
  let(:matrix) { [[0,1,1], [0,0,0], [0,0,0]] }

  describe '#groups_of_two' do
    subject { Trixer::Combinator.new(matrix: matrix).groups_of_two }

    it do
      is_expected.to eql([Set[0,1], Set[0,2]])
    end

  end

  describe '#calculate' do
    let!(:combinator) { Trixer::Combinator.new(matrix: matrix) }
    subject { combinator.calculate }

    it do
      is_expected.to eql({ 2 => [Set[0,1],Set[0,2]], 3 => [Set[2,0,1]] })
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
      it { expect(subject[2]).to eql([Set[0,1],Set[0,4],Set[1,2],Set[2,3],Set[5,6],Set[7,8]]) }
      it { expect(subject[3]).to eql([Set[4,0,1], Set[0,2,1], Set[1,3,2]]) }
      it { expect(subject[4]).to eql([Set[4, 0, 2, 1], Set[0, 3, 2, 1]]) }
      it { expect(subject[5]).to eql([Set[4, 0, 3, 2, 1]]) }
      it { expect(subject[6]).to eql([]) }
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

end
