module Qernel::Plugins
  module Merit
    class PowerToHeatAdapter < StorageAdapter
      def inject!
        target = target_api

        full_load_hours =
          participant.production * output_efficiency / (
            participant.input_capacity_per_unit *
            participant.number_of_units *
            3600
          )

        if ! full_load_hours || full_load_hours.nan?
          full_load_seconds = full_load_hours = 0.0
        else
          full_load_seconds = full_load_hours * 3600
        end

        target[:full_load_hours]   = full_load_hours
        target[:full_load_seconds] = full_load_seconds

        target.demand =
          full_load_seconds *
          @converter.input_capacity *
          participant.number_of_units
      end

      private

      def producer_attributes
        attrs = super

        attrs[:decay] =
          @converter.number_of_units.zero? ? ->(*) { 0.0 } : reserve_decay

        # Do not emit anything; it has been converted to hot water.
        attrs[:output_capacity_per_unit] = 0.0

        attrs
      end

      def reserve_decay
        # Remove from the storage ("buffer") as much as possible to satisfy
        # the demand profile.
        decay = subtraction_profile
        ->(point, _) { decay.get(point) }
      end

      def subtraction_profile
        demand_profile *
          @graph.converter(@config.demand_source).converter_api.demand
      end

      def demand_profile
        @dataset.load_profile(@config.demand_profile)
      end
    end # PowerToHeatAdapter
  end # Merit
end
