module Qernel
  module Circularity
    class Manager
      # Array of Qernel::Circularity::Circuit's from etsource cache goes inside!
      def initialize(graph, circuits)
        @graph = graph
        @circuits = circuits.to_solvable(graph)
      end

      def calculate_net_graph
        # pls make this more ruby
        while (circuit = next_circuit)
          next if circuit.solved?

          circuit.solve
        end

        # calculate shares!
      end

      private

      def next_circuit
        # TODO: check which couple of nodes occurs the most
        # for now we pick lowest length
        sorted.pop
      end

      def sorted
        @sorted ||= @circuits.sort_by(&:length)
      end

      def calculate_shares!
        # TODO: calculate all new net demands on nodes
        # This should be a method on SolvableCircuit
        # that calls a net demand method on affected nodes

        # TODO: calculate all new shares of slots and edges for RF
        # Also a method on SolvableCircuit
        # that calls a net demand method on affected nodes

        # Could it be the same method?
      end
    end
  end
end
