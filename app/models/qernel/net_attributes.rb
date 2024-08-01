# frozen_string_literal: true

module Qernel
  # Include attributes and calculation for net attributes needed for Circularity
  # calculations
  module NetAttributes
    def net_demand
      @net_demand ||= demand
    end

    def net_subtract(amount)
      @net_demand = net_demand - amount
    end

    # TODO: methods for calculating shares
  end
end
