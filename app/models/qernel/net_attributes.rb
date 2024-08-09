# frozen_string_literal: true

module Qernel
  # Include attributes and calculation for net attributes needed for Circularity
  # calculations
  module NetAttributes
    # Base net_demand attributes for Nodes and Edges
    module Base
      def net_demand
        return demand unless @net_demand

        @net_demand
      end

      def net_subtract(amount)
        @net_demand = net_demand - amount
      end
    end

    # Edges will also need net_shares to be set
    module Edge
      include Base

      def net_share
        return share unless @net_share

        @net_share
      end

      def net_share=(val)
        @net_share = val
      end

      def reset_net_values!
        @net_demand = demand
        @net_share = share
      end
    end

    # Nodes have to recalculate all net attributes of edges and slots in order
    # for RecursiveFactor to be able to pick them up
    module Node
      include Base

      def net_loss_output_conversion
        if loss_output_conversion.zero?
          0.0
        else
          output(:loss).net_conversion
        end
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

      def reset_net_values!
        @net_demand = demand
        slots.each(&:reset_net_values!)
        input_edges.each(&:reset_net_values!)
        output_edges.each(&:reset_net_values!)
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
        return conversion unless @net_conversion

        @net_conversion
      end

      def net_conversion=(val)
        @net_conversion = val
      end

      def reset_net_values!
        @net_conversion = conversion
      end

      # Sets net shares on the edges based on net demands on the edges,
      # to be used by recursive factor
      def set_net_edge_shares
        edge_demand = edges.filter_map(&:net_demand).sum.to_f

        edges.each do |edge|
          next if edge.net_demand.blank?

          edge.net_share = edge.net_demand / edge_demand
        end
      end
    end
  end
end
