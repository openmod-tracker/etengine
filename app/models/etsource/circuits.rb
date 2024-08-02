# frozen_string_literal: true

module Etsource
  # Class to cache elementary circuits found in the graph
  class Circuits
    def initialize(turbine_circuits, etengine_class)
      @circuits = turbine_circuits
      @etengine_class = etengine_class
    end

    def import
      @circuits.map do |circuit|
        @etengine_class.new(circuit.map(&:key))
      end
    end
  end
end
