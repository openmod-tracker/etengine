# frozen_string_literal: true

module Qernel::Plugins
  # Graph plugin that solves circularities in the graph before recursive factors can run
  # Sets NetAttributes on Nodes, Edges and Slots
  class Circularity
    include Plugin

    after :calculation, :solve_circuits

    def initialize(graph)
      super

      @circularity = Qernel::Circularity::Manager.new(graph, circuits)
    end

    def solve_circuits
      @circularity.calculate_net_graph
    end

    private

    def circuits
      # GRAB FROM ETSOURCE
      graph.circuits.transform_values { |c| c.map(&:key) }
    end
  end
end
