# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Defines a set of consumers and producers which will be computed in Fever.
    # For example, :space_heating or :hot_water. Each group is run in a separate
    # Fever instance.
    class Group
      attr_reader :name

      # Public: Creates a new Group.
      #
      # name    - The name of the group as a Symbol.
      # graph   - The Qernel::Graph containing the converters and demands.
      # dataset - Atlas::Dataset for the current region.
      #
      # Returns a Group.
      def initialize(name, plugin)
        @name    = name
        @graph   = plugin.graph
        @dataset = plugin.dataset
      end

      # Public: The Fever calculation which will compute the group.
      def calculator
        @calculator ||= Fever::Calculator.new(consumer, activities)
      end

      # Public: Instructs the calculator to compute a single frame.
      #
      # frame - The frame number to be calculated.
      #
      # Returns nothing.
      delegate :calculate_frame, to: :calculator

      # Public: Returns a curve which describes the demand for electricity
      # caused by the activities within the calculator.
      def elec_demand_curve
        @elec_demand_curve ||= ElectricityDemandCurve.from_adapters(adapters)
      end

      # Internal: The adapters which map converters from the graph to activities
      # within Fever.
      def adapters
        adapters_by_type.values.flatten
      end

      # Internal: Maps Fever types (:consumer, :storage, etc) to adapters.
      def adapters_by_type
        return @adapters if @adapters

        @adapters =
          Manager::TYPES.each_with_object({}) do |type, data|
            data[type] =
              Etsource::Fever.group(@name).keys(type).map do |node_key|
                Adapter.adapter_for(
                  @graph.converter(node_key), @graph, @dataset
                )
              end
          end
      end

      private

      def consumer
        if adapters_by_type[:consumer].length == 1
          return adapters_by_type[:consumer].first.participant
        end

        # Group has multiple consumers; Fever supports only one so we need to
        # create a new consumer summing the individual demand curves.
        Fever::Consumer.new(
          Merit::CurveTools.add_curves(
            adapters_by_type[:consumer].map do |adapter|
              adapter.participant.demand_curve
            end
          ).to_a
        )
      end

      def activities
        storage = adapters_by_type[:storage]
          .select(&:installed?)
          .map(&:participant)

        producers = adapters_by_type[:producer]
          .select(&:installed?)
          .map(&:participant)

        [storage, producers]
      end
    end
  end
end
