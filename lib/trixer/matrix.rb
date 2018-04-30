module Trixer
  class Matrix

    class << self

      def from_adjacency_list(adjacency_list:, objects: nil)
        objects = adjacency_list.keys if objects.nil?
        matrix = Array.new(objects.size) { Array.new(objects.size) { 0 } }
        objects.each_with_index do |obj, i|
          adjacency_list[obj].each do |linked_obj|
            j = objects.index(linked_obj)
            matrix[i][j] = 1 if j
          end
        end
        matrix
      end

    end

  end
end
