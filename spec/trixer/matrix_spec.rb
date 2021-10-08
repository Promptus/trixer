RSpec.describe Trixer::Matrix do
  
  describe '::from_adjacency_list' do

    let(:objects) { %w(1 2 3 4 5 6) }
    let(:adjacency_list) do
      {
        '1' => ['2', '4', '5'],
        '2' => ['1'],
        '3' => ['4'],
        '4' => ['1', '3', '6'],
        '5' => ['1'],
        '6' => ['4'],
      }
    end

    subject { Trixer::Matrix.from_adjacency_list(adjacency_list: adjacency_list, objects: objects) }

    it do
      is_expected.to eql([
       # 1 2 3 4 5 6
        [0,1,0,1,1,0], # 1
        [1,0,0,0,0,0], # 2
        [0,0,0,1,0,0], # 3
        [1,0,1,0,0,1], # 4
        [1,0,0,0,0,0], # 5
        [0,0,0,1,0,0], # 6
      ])
    end

    context  do
      let(:objects) { %w(1 2 3) }
      let(:adjacency_list) do
        {
          '1' => %w(3),
          '2' => [],
          '3' => []
        }
      end
      it do
        is_expected.to eql([
         # 1 2 3
          [0,0,1], # 1
          [0,0,0], # 2
          [1,0,0], # 3
        ])
      end

      context 'reversed objects' do
        let(:objects) { %w(3 2 1) }

        it do
          is_expected.to eql([
           # 1 2 3
            [0,0,1], # 1
            [0,0,0], # 2
            [1,0,0], # 3
          ])
        end
      end

    end

    context 'subset of objects' do
      let(:objects) { %w(1 2 4 6) }

      it do
        is_expected.to eql([
         # 1 2 3 4 
          [0,1,1,0], # 1
          [1,0,0,0], # 2
          [1,0,0,1], # 3
          [0,0,1,0], # 4
        ])
      end
    end
  end

end
