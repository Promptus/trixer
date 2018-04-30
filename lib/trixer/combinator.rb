module Trixer
  class Combinator

    attr_reader :matrix
    attr_reader :size
    attr_reader :objects

    def initialize(matrix: nil, adjacency_list: nil)
      if adjacency_list
        @objects = adjacency_list.keys
        @matrix = Matrix.from_adjacency_list(adjacency_list: adjacency_list, objects: @objects)
      elsif matrix
        @matrix = matrix.dup
      else
        raise 'Provide either a matrix or an adjacency list'
      end
      @size = @matrix.size
      @groups = {}
    end

    def combinations(objects: nil)
      calculate if @groups.empty?
      res = []
      @groups.each do |group_size, sub_groups|
        sub_groups.each do |group|
          res << group.map { |i| @objects.nil? ? i : @objects[i] }
        end
      end
      res
    end
      
    def calculate
      @groups[2] = groups_of_two
      if @size > 2
        (3..matrix.size).each do |group_size|
          break unless calculate_groups(group_size)
        end
      end
      @groups
    end

    def calculate_groups(group_size)
      previous_groups = @groups[group_size-1]
      return false if previous_groups.nil?
      @groups[group_size] = Set[]
      previous_groups.each do |group|
        group.each_with_index do |node, i|
          matrix[node].each_with_index do |is_linked, neighbour|
            if is_linked == 1 && !group.include?(neighbour)
              new_group = group.dup
              new_group << neighbour
              @groups[group_size] << new_group
            end
          end
        end
      end
      true
    end

    def groups_of_two
      groups = Set[]
      for x in (0..@size-1)
        for y in (x+1..@size-1)
          groups << Set[x, y] if @matrix[x][y] == 1
        end
      end
      groups
    end
  end
end
