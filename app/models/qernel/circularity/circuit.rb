module Qernel
  module Circularity
    # Elementary circuits that are cached by ETSource
    class Circuit
      # Turbine::Node array - first and last are the same
      # Should become list of keys
      def initialize(node_keys)
        @node_keys = node_keys
      end

      def to_solvable(graph)
        SolvableCircuit.new(@node_keys.map { |key| graph.node(key) })
      end
    end

    # Circuits connecting nodes in the graph
    class SolvableCircuit
      delegate :length, to: :@nodes

      # Or we init with keys and graph, if we think we need the graph? Maybe that's more neat
      def initialize(nodes)
        @nodes = nodes
      end

      def solved?
        zero_node_demand? || zero_edge_demand?
      end

      def edges
        @edges ||= @nodes[...-1].each_with_index.map do |node, index|
          node.output_edges.find { |edge| edge.lft_node.key == @nodes[index + 1].key }
        end
      end

      def total_edge_demand
        edges.sum(&:net_demand)
      end

      def lowest_edge_demand
        edges.map(&:net_demand).min
      end

      # Public: Solves the circuit
      #
      # Subtract the lowest edge demand from all other edges in the circuit to create one zero
      # edge
      def solve
        min_demand = lowest_edge_demand
        edges.each { |edge| edge.net_subtract(min_demand) }
      end

      private

      # Returns true if there is at least one node with zero demand in the circuit
      def zero_node_demand?
        @nodes.any? { |node| node.demand.zero? }
      end

      # Returns true if there is at least one edge with zero demand in the circuit
      def zero_edge_demand?
        edges.any? { |edge| edge.net_demand.zero? }
      end
    end
  end
end
