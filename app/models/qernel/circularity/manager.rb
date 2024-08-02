# frozen_string_literal: true

module Qernel
  module Circularity
    # Solves circuits in the graph and sets net attributes for RecursiveFactor
    class Manager
      # Array of Qernel::Circularity::Circuit's from etsource cache goes inside!
      def initialize(graph, circuits)
        @graph = graph
        @circuits = circuits.map { |c| c.to_solvable(graph) }
      end

      def calculate_net_graph
        # TODO: pls make this more ruby
        while (circuit = next_circuit)
          next if circuit.solved?

          circuit.solve
        end

        calculate_shares!
      end

      private

      def next_circuit
        resort
        sorted.pop
      end

      def sorted
        @sorted ||= @circuits.sort_by(&:length)
      end

      # TODO: discussed algorithm:
      # - Check which couple of nodes occurs the most
      # - Of these couples, pick the circuit with lowest length
      # - If multiple, pick circuit with highest total demand OR with highest lowest_edge_demand?
      # For now we pick lowest length, so no resorting needed yet
      def resort; end

      def calculate_shares!
        @circuits.each(&:recalculate_net_values!)
      end
    end
  end
end
