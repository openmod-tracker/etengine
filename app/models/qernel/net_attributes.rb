# frozen_string_literal: true

module Qernel
  # Include attributes and calculation for net attributes needed for Circularity
  # calculations
  module NetAttributes
    # Base net_demand attributes for Nodes and Edges
    module Base
      def net_demand
        @net_demand ||= demand
      end

      def net_subtract(amount)
        @net_demand = net_demand - amount
      end
    end

    # Edges will also need net_shares to be set
    module Edge
      include Base

      def net_share
        @net_share ||= share
      end

      def net_share=(val)
        @net_share = val
      end
    end

    # Nodes have to recalculate all net attributes of edges and slots in order
    # for RecursiveFactor to be able to pick them up
    module Node
      include Base

      def net_loss_output_conversion
        @net_loss_output_conversion ||= loss_output_conversion
      end

      def recalculate_net_values!
        # TODO: Slot conversion and edge share net attriubtes based on
        # node and edge net_demand
        # make sure to grab both input and output slots
      end
    end

    # Net attributes for Slots
    module Slot
      # TODO: Probably we need this too??
      def net_external_value
        edge_demand = edges.filter_map(&:net_demand).sum.to_f

        if has_reversed_shares?
          edge_demand / reversed_share_compensation
        else
          edge_demand
        end
      end

      def net_conversion
        @net_conversion ||= conversion
      end

      def net_conversion=(val)
        @net_conversion = val
      end
    end
  end
end
