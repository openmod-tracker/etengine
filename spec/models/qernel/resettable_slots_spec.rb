require 'spec_helper'

module Qernel
  describe Converter do
    describe "max_demand_recursive" do
      before do 
        @gql = Scenario.default.gql
      end

      it "equals max_demand if max_demand is available"  do
        expect(@gql.query_future("V(resettable_slots_with_hidden_link, demand)")).to eq(11000.0)
        expect(@gql.query_future("V(resettable_slots_with_hidden_link_child, demand)")).to eq(11000.0)
        expect(@gql.query_future("V(resettable_slots_with_hidden_link_child, primary_demand)")).to eq(11000.0)
        expect(@gql.future_graph.converter(:resettable_slots_with_hidden_link_child).primary_energy_demand?).to be_truthy
        expect(@gql.query_future("V(resettable_slots_with_reset_slot, primary_demand)")).to eq(0.0)
        expect(@gql.query_future("V(resettable_slots_with_hidden_link, primary_demand)")).to eq(11000.0)
      end
    end
  end
end
