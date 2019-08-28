# frozen_string_literal: true

module Qernel
  module MeritFacade
    # An adapter which does not adjust the merit order output for loss, since
    # the converter will account for that instead.
    class PowerToGasAdapter < FlexAdapter
      def inject!
        super

        @converter.dataset_lazy_set(:electricity_input_curve) do
          participant.load_curve.to_a.map(&:abs)
        end
      end

      private

      def output_efficiency
        1.0
      end
    end
  end
end
