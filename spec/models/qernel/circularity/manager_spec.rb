# frozen_string_literal :true

RSpec.describe Qernel::Circularity::Manager do
  # Uses the following example graph:
  #
  #                     +----------+
  #                     |          v
  #     [far_left] <- [left] <- [middle] <- [right]
  #      0.5   loss <-| 2.5      2.5  ^      1
  #             0.5   v               |
  #                [down_left] -> [down]
  #                   0.5          0.5

  subject { described_class.new(graph, [circuit, circuit2])}

  let(:builder) do
    TestGraphBuilder.new.tap do |builder|
      builder.add(:left, demand: 2.5)
      builder.add(:middle, demand: 2.5)
      builder.add(:right, demand: 1, groups: %i[primary_energy_demand])

      builder.connect(:right, :middle, :natural_gas, type: :share)
      builder.connect(:middle, :left, :natural_gas, type: :share)

      builder.add(:far_left, demand: 0.5)
      builder.connect(:left, :far_left, :coal)
      builder.connect(:left, :middle, :natural_gas, circular: true)

      builder.add(:down_left, demand: 0.5)
      builder.connect(:left, :down_left, :ammonia)
      builder.add(:down, demand: 0.5)
      builder.connect(:down_left, :down, :ammonia)
      builder.connect(:down, :middle, :natural_gas, circular: true)

      builder.node(:left).slots.out(:natural_gas).set(:share, 0.4)
      builder.node(:left).slots.out(:coal).set(:share, 0.2)
      builder.node(:left).slots.out(:ammonia).set(:share, 0.2)
      builder.node(:left).slots.out.add(:loss, share: 0.2)
    end
  end

  let(:graph) { builder.to_qernel }

  let(:circuit) { Qernel::Circularity::Circuit.new(%i[left middle left]) }

  let(:circuit2) { Qernel::Circularity::Circuit.new(%i[down middle left down_left down]) }

  context 'when calculating a net graph for a graph with two overlapping circuits' do
    before { subject.calculate_net_graph }

    it 'leaves 1.0 net_demand on the edge between middle and left' do
      expect(graph.node(:middle).output_edges.first.net_demand).to eq(1.0)
    end

    it 'does not touch demand on the edge between middle and left' do
      expect(graph.node(:middle).output_edges.first.demand).to eq(2.5)
    end

    it 'sets net_demand on the middle node' do
      expect(graph.node(:middle).net_demand).to eq(1.0)
    end

    it 'sets net_demand on the left node' do
      expect(graph.node(:left).net_demand).to eq(1.0)
    end

    it 'corrects the coal slot net_conversion on the left node' do
      expect(graph.node(:left).output(:coal).net_conversion).to eq(0.5)
    end

    it 'corrects the ammonia slot net_conversion on the left node' do
      expect(graph.node(:left).output(:ammonia).net_conversion).to eq(0.0)
    end

    it 'does not change the share on the left nodes coal output edge' do
      coal_output_edge = graph.node(:left).output(:coal).edges.first
      expect(coal_output_edge.net_share).to eq(coal_output_edge.share)
    end
  end
end
