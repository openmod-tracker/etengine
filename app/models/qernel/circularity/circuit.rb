module Qernel
  module Circularity
    # Elementary circuits that are cached by ETSource
    class Circuit
      # Turbine::Node array - first and last are the same is what comes in from
      # Turbine::Graph.circuits
      # Should become list of keys of affected nodes to cache properly
      def initialize(node_keys)
        @node_keys = node_keys
      end

      def to_solvable(graph)
        SolvableCircuit.new(@node_keys.filter_map { |key| graph.node(key) })
      end
    end

    # Circuits connecting nodes in the graph
    class SolvableCircuit
      delegate :length, to: :@nodes

      # Or we init with keys and graph, if we think we need the graph? Maybe that's more neat
      def initialize(nodes)
        @nodes = nodes
      end

      # Public: A circuit is solved when one of the edges or nodes contains zero
      # net demand. No Qernel calculations will traverse 'empty' nodes or edges.
      def solved?
        zero_node_demand? || zero_edge_demand?
      end

      # Public: All edges between the nodes in the circuit
      #
      # Returns an array of Qernel::Edge's
      def edges
        @edges ||= @nodes[...-1].each_with_index.map do |node, index|
          node.output_edges.find { |edge| edge.lft_node.key == @nodes[index + 1].key }
        end
      end

      # Public: Total (net) demand over all edges
      #
      # Returns a float
      def total_edge_demand
        edges.sum(&:net_demand)
      end

      # Public: The lowest (net) demand found on an edge
      #
      # Returns a float
      def lowest_edge_demand
        edges.map(&:net_demand).min
      end

      # Public: Solves the circuit
      #
      # Subtract the lowest edge demand from all other edges in the circuit to create one zero
      # edge. Also substracts this net_demand from affected nodes
      def solve
        min_demand = lowest_edge_demand
        edges.each { |edge| edge.net_subtract(min_demand) }
        @nodes[...-1].each { |node| node.net_subtract(min_demand) }
      end

      # Public: Calls nodes, slots and edges to recalculate net demands, shares and
      # conversion based on net_demand set by solving
      #
      # Assumes this method is called only after solving
      def recalculate_net_values!
        @nodes.each(&:recalculate_net_values!)
      end

      private

      # Private: Is there at least one node with zero demand in the circuit
      def zero_node_demand?
        @nodes.any? { |node| node.net_demand.zero? }
      end

      # Private: is there at least one edge with zero demand in the circuit
      def zero_edge_demand?
        edges.any? { |edge| edge.net_demand.zero? }
      end
    end
  end
end
