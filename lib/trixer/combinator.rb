module Trixer
  class Combinator

    attr_reader :matrix
    attr_reader :size

    def initialize(matrix:)
      @matrix = matrix.dup
      @size = @matrix.size
      @groups = {}
      @hashes = {}
    end
      
    def calculate
      @groups[2] = groups_of_two
      (3..matrix.size).each do |group_size|
        break unless calculate_groups(group_size)
      end
      @groups
    end

    def calculate_groups(group_size)
      previous_groups = @groups[group_size-1]
      return false if previous_groups.nil?
      @groups[group_size] = []
      @hashes[group_size] = {}
      previous_groups.each do |group|
        group.each_with_index do |node, i|
          matrix[node].each_with_index do |is_linked, neighbour|
            if is_linked == 1 && !group.include?(neighbour)
              new_group = group.dup
              new_group << neighbour
              add_group(group_size, new_group)
            end
          end
        end
      end
      true
    end

    def add_group(group_size, new_group)
      group_hash = new_group.hash
      if @hashes[group_size][group_hash].nil?
        @hashes[group_size][group_hash] = true
        @groups[group_size] << new_group
      end
    end

    def groups_of_two
      groups = []
      for x in (0..@size-1)
        for y in (x+1..@size-1)
          groups << Set[x, y] if @matrix[x][y] == 1
        end
      end
      groups
    end
  end
end
