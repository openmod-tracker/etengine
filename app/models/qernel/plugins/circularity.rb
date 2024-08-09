# frozen_string_literal: true

module Qernel::Plugins
  # Graph plugin that solves circularities in the graph before recursive factors can run
  # Sets NetAttributes on Nodes, Edges and Slots
  module Circularity
    # include Plugin

    # # Net graph has to be created before recursive factors start, but after
    # # TODO: does it have to run twice? Yes
    # before :first_calculation, :solve_circuits
    # # Has to run before merit!!
    # after :first_calculation, :clean_up
    # after :first_calculation, :solve_circuits
    # after :calculation, :clean_up
    # after :calculation, :solve_circuits

    def circularity
      @circularity ||= Qernel::Circularity::Manager.new(self, circuits)
    end

    def solve_circuits
      circularity.calculate_net_graph
    end

    def clean_up_circuits
      circularity.reset!
    end

    private

    def circuits
      Etsource::Loader.instance.circuits
    end
  end
end
