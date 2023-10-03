# frozen_string_literal: true

module Qernel
  module FeverFacade
    # A demand curve that is smoothed to show the multitude of different
    # behaviours of people using heating and hot water.
    class SmoothedDemandCurve
      include Enumerable

      # Helper class to generate normally distributed numbers
      class RandomGaussian

        # TODO: add a seed!! Or have it as som ekind of static curve of deviations so that
        # it is alwasy the same!! ASK ROOS
        def initialize(mean = 0.0, sd = 1.0, rng = lambda { Kernel.rand })
          @mean, @sd, @rng = mean, sd, rng
          @compute_next_pair = false
        end

        def rand
          if (@compute_next_pair = !@compute_next_pair)
            # Compute a pair of random values with normal distribution.
            # See http://en.wikipedia.org/wiki/Box-Muller_transform
            theta = 2 * Math::PI * @rng.call
            scale = @sd * Math.sqrt(-2 * Math.log(1 - @rng.call))
            @g1 = @mean + scale * Math.sin(theta)
            @g0 = @mean + scale * Math.cos(theta)
          else
            @g1
          end
        end
      end

      INTERPOLATION_STEPS = 10
      DIFFERENT_BEHAVIOURS = 300

      # What about insulation type - there was a different number for each in the original script?
      HOURS_SHIFTED = 2.5

      def initialize(name, node, context)
        @initial_curve = context.curves.curve(name, node)
        @demand = node.demand
      end

      # Internal: Prevents Fever from trying to coerce the object into an array.
      # TODO: we need this?
      def to_curve
        self
      end

      # yo yo main method!!
      def smoothed_curve
        # puts interpolated_curve[0..10]
        puts deviations[0..10]
        # for each random number, shift the demand curve X places forwards or
        # backwards (depending on the number value) and add it to the
        # cumulative demand array
        cumulative_demand = (0...interpolated_curve.length).map do |i|
          deviations.inject(0) do |sum, dev|
            next_index = i + dev
            next_index -= interpolated_curve.length if next_index >= interpolated_curve.length
            sum + interpolated_curve[next_index]
          end
        end

        # TODO: trim back!

        cumulative_demand
      end

      private

      # Internal: Generate DIFFERENT_BEHAVIOURS amount of random numbers with a standard deviation
      # of HOURS_SHIFTED hours
      # Round to 1 decimal place and multiply by 10 to get integer value. The number designates
      # the number of 6 minute time slots the demand profile will be shifted compared to the
      # original demand profile. E.g. '15' means that the demand profile will be shifted forward
      # 1.5 hours, '-10' means it will be shifted backwards 1 hour
      def deviations
        @deviations ||= (0...DIFFERENT_BEHAVIOURS).map do |_|
          distribution.rand.round(1) * INTERPOLATION_STEPS
        end
      end

      # Internal: interpolate the demand curve to increase the number of data points
      # (i.e. reduce the time interval 1 hour to e.g. 6 minutes)
      def interpolated_curve
        @interpolated_curve ||= @initial_curve.to_a.interpolate(INTERPOLATION_STEPS)
      end

      def distribution
        @distribution ||= Qernel::FeverFacade::SmoothedDemandCurve::RandomGaussian.new(0.0, HOURS_SHIFTED)
      end
    end
  end
end

# Adds the interpolation method directly on Array
class Array
  # TODO: wrap around!
  def interpolate(times)
    return unless times.positive?

    h, *t = self
    return [h] if t.empty?

    t.inject([h]) do |a, e|
      step = (e - h) / times
      (1...times).each { |i| a.push(h + (i * step)) }
      a.push(h = e)
    end
  end
end
