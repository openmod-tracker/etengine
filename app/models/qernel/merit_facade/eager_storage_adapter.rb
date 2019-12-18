# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sets up storage in Merit; typically used for household batteries or
    # storage in electric vehicles.

    # Eager storage will consume energy from dispatchables in order to fill its
    # reserve. It may also emit energy in the same frame as it consumed, meaning
    # that the Merit participant has separate input and output curves.
    class EagerStorageAdapter < StorageAdapter
      def producer_class
        Merit::Flex::EagerStorage
      end

      def inject!
        super

        inject_curve!(:input) { @participant.input_curve.dup }
        inject_curve!(:output) { @participant.output_curve.dup }
      end

      def producer_attributes
        attrs = super

        # EagerStorage needs a cost for the heat network calculation to ensure
        # correct sorting.
        attrs[:marginal_costs] = @context.dispatchable_sorter.cost(@converter)

        attrs
      end

      private

      def producer_output
        @participant.output_curve.sum
      end
    end
  end
end
