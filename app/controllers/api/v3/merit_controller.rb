module Api
  module V3
    class MeritController < BaseController
      respond_to :json
      respond_to :csv, only: [:load_curves, :price_curve, :heat_curves]

      rescue_from ActiveRecord::RecordNotFound do
        render json: { errors: ['Scenario not found'] }, status: 404
      end

      # Downloads the load on each participant in the merit order as a CSV.
      #
      # GET /api/v3/scenarios/:scenario_id/merit/loads.csv
      def load_curves
        send_csv('loads') do |csv|
          merit_order.load_curves.each { |row| csv << row }
        end
      end

      # Downloads the merit order price for each hour of the year as a CSV.
      #
      # GET /api/v3/scenarios/:scenario_id/merit/price.csv
      def price_curve
        send_csv('price') do |csv|
          merit_order.price_curve.each { |row| csv << [row] }
        end
      end

      # Downloads the supply and demand of heat, including deficits and
      # surpluses due to buffering and time-shifting.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/heat.csv
      def heat_curves
        summary = scenario.gql.future_graph.plugin(:time_resolve).fever.summary

        rows = summary.production.zip(
          summary.demand,
          summary.surplus,
          summary.deficit
        )

        send_csv('heat_demand') do |csv|
          csv << [
            'Production',
            'Demand',
            'Buffering and time-shifting',
            'Deficit'
          ]

          rows.each { |row| csv << row.flatten }
        end
      end

      private

      def send_csv(name)
        send_data(
          CSV.generate { |csv| yield csv },
          type: 'text/csv',
          filename: "#{ name }.#{ scenario.id }.csv"
        )
      end

      def merit_order
        @mo ||= Qernel::Plugins::MeritOrder.new(
          scenario.gql.future_graph
        ).order.calculate
      end

      def scenario
        @scenario ||=
          Preset.get(params[:scenario_id]).try(:to_scenario) ||
          Scenario.find(params[:scenario_id])
      end
    end # MeritController
  end # V3
end # Api
