class KeepCompatible < ActiveRecord::Migration[7.0]
  # This migration sets some scenarios that missed some migrations to keep compatible and
  # reapplies the missed migrations
  AFFECTED_SCENARIOS = [
    953308, 953309, 953310, 953311, 953312, 953313, 953314, 953315, 953316,
    953317, 953318, 953319, 953320, 953321, 953322, 953323, 953324, 953325,
    953326, 953327, 953328, 953329, 953330, 953331, 953338, 953339, 953340,
    953332, 953333, 953334, 953221, 953222, 953223, 953335, 953336, 953337,
    953341, 953342, 953343, 953344, 953345, 953346, 953347, 953348, 953349,
    953350, 953351, 953352, 953353, 953354, 953355, 953356, 953357, 953358,
    953359, 953360, 953361, 953362, 953363, 953364, 953365, 953366, 953367,
    953368, 953369, 953370, 953371, 953372, 953373, 953374, 953375, 953376,
    953377, 953378, 953379, 953380, 953381, 953382, 953383, 953384, 953385,
    953386, 953387, 953388, 953227, 953228, 953229, 953230, 953231, 953232,
    953233, 953234, 953235, 953236, 953237, 953238, 953239, 953240, 953241,
    953242, 953243, 953244, 953245, 953246, 953247, 953248, 953249, 953250,
    953257, 953258, 953259, 953251, 953252, 953253, 953224, 953225, 953226,
    953254, 953255, 953256, 953260, 953261, 953262, 953263, 953264, 953265,
    953266, 953267, 953268, 953269, 953270, 953271, 953272, 953273, 953274,
    953275, 953276, 953277, 953278, 953279, 953280, 953281, 953282, 953283,
    953284, 953285, 953286, 953287, 953288, 953289, 953290, 953291, 953292,
    953293, 953294, 953295, 953296, 953297, 953298, 953299, 953300, 953301,
    953302, 953303, 953304, 953305, 953306, 953307
  ].freeze

  # iNET Q4
  AGRI_HEAT_GROUP = %i[
    agriculture_burner_crude_oil_share
    agriculture_burner_hydrogen_share
    agriculture_burner_network_gas_share
    agriculture_burner_wood_pellets_share
    agriculture_geothermal_share
    agriculture_heatpump_water_water_electricity_share
    agriculture_heatpump_water_water_ts_electricity_share
  ]

  AGRI_LOCAL_CHPS = %i[
    capacity_of_agriculture_chp_engine_biogas
    capacity_of_agriculture_chp_engine_network_gas_dispatchable
    capacity_of_agriculture_chp_engine_network_gas_must_run
    capacity_of_agriculture_chp_wood_pellets
  ].freeze

  ENERGY_CHPS = %i[
    capacity_of_energy_chp_local_engine_network_gas
    capacity_of_energy_chp_local_engine_biogas
    capacity_of_energy_chp_local_wood_pellets
  ].freeze


  def up
    default_values = JSON.load(File.read(
      Rails.root.join("db/migrate/20230113121420_inet_q4_inputs/defaults.json")
    ))

    scenarios do |scenario|
      scenario.keep_compatible = true

      # Rename ammonia slider
      rename_ammonia(scenario)

      # iNET Q4
      inet_q4_change(default_values, scenario)
    end
  end

  def down

  end



  private

  def inet_q4_change(default_values, scenario)
    defaults = default_values[scenario.area_code.to_s]

    return unless defaults.present?

    # Agriculture heating technology inputs
    # -------------------------------------

    # - Set agriculture_final_demand_local_steam_hot_water_share to 0.0
    scenario.user_values[:agriculture_final_demand_local_steam_hot_water_share] = 0.0

    # - Set agriculture_final_demand_central_steam_hot_water_share to the current value of
    #   agriculture_final_demand_steam_hot_water_share
    #
    # - Remove agriculture_final_demand_steam_hot_water_share from inputs
    scenario.user_values[:agriculture_final_demand_central_steam_hot_water_share] =
      scenario.user_values.delete(:agriculture_final_demand_steam_hot_water_share) ||
      defaults['agriculture_final_demand_steam_hot_water_share']

    # - Set all remaining inputs in the share_group = agri_heat to the current value
    #
    # If any of the inputs in the group are set, leave the values as they are, otherwise set
    # them to the values exported from production.
    unless AGRI_HEAT_GROUP.any? { |key| scenario.user_values.key?(key) }
      AGRI_HEAT_GROUP.each do |key|
        scenario.user_values[key] = defaults[key.to_s]

        # Remove any auto-set value for the input.
        scenario.balanced_values.delete(key)
      end
    end

    # Agriculture local CHP inputs
    # ---------------------------

    # - Set all inputs to 0.0
    AGRI_LOCAL_CHPS.each do |key|
      scenario.user_values[key] = 0.0
    end

    # Energy CHPs
    # -----------

    # - Set all inputs to the current value
    #
    # If the input already has a value, leave it as is, otherwise set them to the values exported
    # from production.
    ENERGY_CHPS.each do |key|
      scenario.user_values[key] ||= defaults[key.to_s]
    end
  end

  def rename_ammonia(scenario)
    rename_input(
      scenario,
      'industry_chemicals_fertilizers_steam_methane_reformer_hydrogen_share',
      'industry_chemicals_fertilizers_local_ammonia_local_hydrogen_share'
    )

    rename_input(
      scenario,
      'industry_chemicals_fertilizers_hydrogen_network_share',
      'industry_chemicals_fertilizers_local_ammonia_central_hydrogen_share'
    )

    if scenario.user_values.key?('industry_chemicals_fertilizers_local_ammonia_central_hydrogen_share') ||
        scenario.user_values.key?('industry_chemicals_fertilizers_local_ammonia_local_hydrogen_share')
      scenario.user_values['industry_chemicals_fertilizers_central_ammonia_share'] = 0.0
    end
  end

  def scenarios
    collection = Scenario.find(AFFECTED_SCENARIOS)
    total = collection.count
    changed = 0

    say("#{total} candidate scenarios for migration")

    collection.each.with_index do |scenario, index|
      begin
        yield(scenario)
      rescue Psych::DisallowedClass
        say("Skipping #{scenario.id} - invalid YAML", true)
      end

      if scenario.changed?
        scenario.save(validate: false, touch: false)
        changed += 1
      end

      if index.positive? && ((index + 1) % 1000).zero?
        say("#{index + 1}/#{total} (#{changed} migrated)")
      end
    end

    say("#{total}/#{total} (#{changed} migrated)")

    nil
  end

  def rename_input(scenario, from, to)
    if scenario.user_values.key?(from)
      scenario.user_values[to] = scenario.user_values.delete(from)
    end
  end
end
