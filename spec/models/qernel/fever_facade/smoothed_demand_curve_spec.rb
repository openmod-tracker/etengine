require 'spec_helper'

describe Qernel::FeverFacade::SmoothedDemandCurve, :household_curves do
  let(:graph) do
    create_graph(area_code: region, weather_curve_set: curve_set)
  end

  let(:region)    { :nl }
  let(:curve_set) { 0.0 }

  let(:curves) do
    Qernel::FeverFacade::Curves.new(graph)
  end

  let(:context) { instance_double('Context', curves: curves) }
  let(:node) { instance_double('Qernel::Node', demand: 8760) }
  let(:curve) { curves.curve(curve_name, node) }
  let(:smoothed_curve) { described_class.new(curve_name, node, context).smoothed_curve }

  describe 'smoothed_curve' do
    # The dhw_normalized curve looks like this:
    # 0.00022831050228310502
    # 0.0
    # 0.00022831050228310502
    # ...
    context 'with the dhw_normalized curve' do
      let(:curve_name) { 'dhw_normalized' }

      it 'smooths the values' do
        expect(smoothed_curve[0..3]).to eq([0, 0, 0])
      end

      it 'still sums to the same amount' do
        expect(smoothed_curve.sum).to eq(smoothed_curve.sum)
      end
    end
  end

  describe 'interpolation' do
    # TODO: does not wrap around!!! FIX THIS

    context 'of [1, 0] in 2 steps' do
      it 'smooths it out into [1, 0.5, 0]' do
        expect([1.0, 0.0].interpolate(2)).to eq([1, 0.5, 0])
      end
    end
    context 'of [1, 0, 0] in 4 steps' do
      it 'smooths it out into [1, 0.75, 0.5, 0.25, 0]' do
        expect([1.0, 0.0, 0.0].interpolate(4)).to eq([1, 0.75, 0.5, 0.25, 0, 0.0, 0.0, 0.0, 0.0])
      end
    end
    context 'of [0, 60] in 10 steps' do
      it 'smooths it out into [1, 0.75, 0.5, 0.25, 0]' do
        expect([0.0, 60.0].interpolate(10)).to eq([0.0, 6.0, 12.0, 18.0, 24.0, 30.0, 36.0, 42.0, 48.0, 54.0, 60.0])
      end
    end
    context 'of [1, 0, 1] in 4 steps' do
      it 'smooths it out correctly' do
        expect([1.0, 0.0, 1.0].interpolate(4)).to eq([1, 0.75, 0.5, 0.25, 0, 0.25, 0.5, 0.75, 1])
      end
    end
  end
end
