module Qernel::RecursiveFactor::WeightedCarrier

  # Carrier Cost can depend on the share of other carriers flowing
  # into it.
  # E.g. Gas price is dependent on the mix of greengas and natural
  # gas.
  #
  # A.carrier_cost_per_mj == 0.4*0.85 + 0.6 * 1.0
  #
  def weighted_carrier_cost_per_mj
    fetch(:weighted_carrier_cost_per_mj) do
      recursive_factor_without_losses(:weighted_carrier_cost_per_mj_factor)
    end
  end

  def weighted_carrier_cost_per_mj_factor(link)
    # because electricity and steam_hot_water are calculated seperately
    # these are excluded from this calculation
    # old: if right_dead_end? and link
    # new: always 0 for elec and steam_hw
    if link
      if (link.carrier.electricity? || link.carrier.steam_hot_water?)
        0.0
      elsif link.carrier.cost_per_mj || right_dead_end?
        link.carrier.cost_per_mj
      else
        nil # continue to the right
      end
    else
      nil # continue to the right
    end
  end

  # Same as weighted_carrier_cost_per_mj but for co2
  #
  def weighted_carrier_co2_per_mj
    fetch(:weighted_carrier_co2_per_mj) do
      recursive_factor_without_losses(:weighted_carrier_co2_per_mj_factor)
    end
  end

  def weighted_carrier_co2_per_mj_factor(link)
    if right_dead_end? and link
      link.carrier.co2_conversion_per_mj
    else
      nil
    end
  end

  # This method is the same as weighted_carrier_cost_per_mj, except
  # it takes into account losses. Therefore, the resulting factor
  # is not normalized to 1. It can only be used with the demand
  # of a converter (not with its primary demand).
  def weighted_carrier_co2_per_mj_incl_losses
    fetch(:weighted_carrier_co2_per_mj) do
      recursive_factor(:weighted_carrier_co2_per_mj_incl_losses_factor)
    end
  end

  def weighted_carrier_co2_per_mj_incl_losses_factor(link)
    if right_dead_end? and link
      link.carrier.co2_conversion_per_mj
    else
      nil
    end
  end

end
