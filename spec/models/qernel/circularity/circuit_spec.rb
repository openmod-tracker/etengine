RSpec.describe Qernel::Circularity::Circuit do
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

  context 'with a node-to-node loop' do
    it 'has length 3' do
      expect(solvable_circuit.length).to eq(3)
    end

    it 'has 2 edges' do
      expect(solvable_circuit.edges.length).to eq(2)
    end

    it 'is not solved' do
      expect(solvable_circuit).not_to be_solved
    end

    context 'when solving the circuit' do
      before { solvable_circuit.solve }

      it 'is solved' do
        expect(solvable_circuit).to be_solved
      end

      it 'shows net demand on the first edge' do
        expect(solvable_circuit.edges.first.net_demand).to be_zero
      end

      it 'shows net demand on the second edgs' do
        expect(solvable_circuit.edges.last.net_demand).to eq(1.0)
      end

      it 'keeps the original demand intact' do
        expect(solvable_circuit.edges.first.demand).to eq(1.0)
      end
    end
  end
end
