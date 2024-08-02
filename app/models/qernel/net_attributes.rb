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
        slots.each do |slot|
          if slot.loss?
            slot.net_conversion = (slot.conversion * node.demand) / net_demand
          else
            slot.net_conversion = slot.net_external_value / net_demand
            slot.set_net_edge_shares
          end
        end
      end
    end

    # Net attributes for Slots
    module Slot
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

      # Sets net shares on the edges based on net demands on the edges,
      # to be used by recursive factor
      def set_net_edge_shares
        edge_demand = edges.filter_map(&:net_demand).sum.to_f

        edges.each do |edge|
          next unless edge.net_demand

          edge.net_share = edge.net_demand / edge_demand
        end
      end
    end
  end
end
