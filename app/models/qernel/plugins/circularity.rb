# frozen_string_literal: true

module Qernel::Plugins
  # Graph plugin that solves circularities in the graph before recursive factors can run
  # Sets NetAttributes on Nodes, Edges and Slots
  class Circularity
    include Plugin

    # Net graph has to be created before recursive factors start, but after
    after :recalculation, :solve_circuits

    def initialize(graph)
      super

      @circularity = Qernel::Circularity::Manager.new(graph, circuits)
    end

    def solve_circuits
      puts circuits
      @circularity.calculate_net_graph
    end

    private

    def circuits
      Etsource::Loader.instance.circuits
    end
  end
end
