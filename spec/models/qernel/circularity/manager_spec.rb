RSpec.describe Qernel::Circularity::Manager do
    # TODO: we need two circuits in this one! Otherwise we cannot test the sorting
    # Three would be even better
    # Use my example from teh basecamp post?

    #                     +----------+
    #                     |          v
    #     [far_left] <- [left] <- [middle] <- [right]
    #      0.5          |  2         2         1
    #             loss(0.5)
    let(:builder) do
      TestGraphBuilder.new.tap do |builder|
        builder.add(:left, demand: 2)
        builder.add(:middle, demand: 2)
        builder.add(:right, demand: 1, groups: %i[primary_energy_demand])

        builder.connect(:right, :middle, :natural_gas, type: :share)
        builder.connect(:middle, :left, :natural_gas, type: :share)

        builder.add(:far_left, demand: 0.5)
        builder.connect(:left, :far_left, :coal)
        builder.connect(:left, :middle, :natural_gas, circular: true)

        builder.node(:left).slots.out(:natural_gas).set(:share, 0.5)
        builder.node(:left).slots.out(:coal).set(:share, 0.25)
        builder.node(:left).slots.out.add(:loss, share: 0.25)
      end
    end

    let(:graph) { builder.to_qernel }

    let(:left) { graph.node(:left) }
    let(:middle) { graph.node(:middle) }
    let(:right) { graph.node(:right) }

    let(:circuit) { described_class.new(%i[left middle left]) }
    let(:solvable_circuit) { circuit.to_solvable(graph) }

end
