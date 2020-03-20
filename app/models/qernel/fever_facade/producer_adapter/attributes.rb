# frozen_string_literal: true

module Qernel
  module FeverFacade
    class ProducerAdapter < Adapter
      # Calculates values used by Fever producers.
      module Attributes
        private

        # Internal: Calculates what share of the total heat demand will be
        # supplied by this producer.
        def share
          link = @converter.converter.output(:useable_heat).links.first

          if link.lft_converter.key.to_s.include?('aggregator')
            link.lft_converter.output(:useable_heat).links.first.share
          else
            link.share
          end
        end

        def output_efficiency
          slots = @converter.converter.outputs.reject(&:loss?)
          slots.any? ? slots.sum(&:conversion) : 1.0
        end

        def input_efficiency
          1.0 / @converter.converter.input(input_carrier).conversion
        end

        # Internal: The capacity of the Fever participant in each frame.
        #
        # Returns an arrayish.
        def capacity
          return total_value(:heat_output_capacity) unless @config.alias_of

          DelegatedCapacityCurve.new(
            total_value(:heat_output_capacity),
            aliased_adapter.participant.producer,
            input_efficiency
          )
        end

        # Internal: Creates a Reserve which can be used by a Fever participant
        # which will buffer energy in a reserve before it is needed.
        #
        # Returns a Merit::Flex::Reserve.
        def reserve
          volume  = total_value { @converter.dataset_get(:storage).volume }
          reserve = Merit::Flex::SimpleReserve.new(volume)

          # Buffer starts full.
          reserve.add(0, volume)

          reserve
        end
      end
    end
  end
end
