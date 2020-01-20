# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Converts a Qernel::Converter to a Merit user.
    class ConsumerAdapter < Adapter
      def self.factory(converter, context)
        case context.node_config(converter).subtype
        when :pseudo
          PseudoConsumerAdapter
        when :consumption_loss
          ConsumptionLossAdapter
        else
          self
        end
      end

      def initialize(*)
        super
        @input_of_carrier = input_of_carrier
      end

      def participant
        @participant ||=
          if @config.group.to_s.starts_with?('self:')
            Merit::User.create(
              key: @converter.key,
              load_curve: @context.curves.curve(@config.group, @converter)
            )
          else
            Merit::User.create(
              key: @converter.key,
              load_profile: consumption_profile,
              total_consumption: @input_of_carrier
            )
          end
      end

      def inject!
        inject_curve!(:input) { @participant.load_curve }
      end

      def input_of_carrier
        if source_api.converter.input(@context.carrier)
          source_api.public_send(@context.carrier_named('input_of_%s'))
        elsif @context.carrier == :electricity &&
            source_api.converter.input(:loss)
          # HV loss node does not have an electricity input; use graph method
          # which compensates for export.
          @context.graph.query.electricity_losses_if_export_is_zero
        else
          raise "No acceptable consumption input for #{source_api.key}"
        end
      end

      def installed?
        @input_of_carrier.positive?
      end

      private

      def consumption_profile
        @context.curves.curve(@config.group, @converter)
      end
    end
  end
end
