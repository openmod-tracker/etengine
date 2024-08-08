# frozen_string_literal: true

module Identity
  class NewsletterController < ApplicationController
    include IdentityController

    before_action :require_mailchimp_configured

    def edit
      return redirect_to(identity_profile_path) unless turbo_frame_request?
    end

    def update
      @subscribed = ActiveModel::Type::Boolean.new.cast(params[:subscribed])
      @changelog_subscribed = ActiveModel::Type::Boolean.new.cast(params[:changelog_subscribed])

      service = if @subscribed
        CreateNewsletterSubscription
      else
        DeleteNewsletterSubscription
      end

      changelog_service = if @changelog_subscribed
        CreateChangelogSubscription
      else
        DeleteChangelogSubscription
      end

      service_result = service.new.call(user: current_user)
      changelog_service_result = changelog_service.new.call(user: current_user)

      if service_result.success? && changelog_service_result.success?
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to(identity_profile_path) }
        end
      else
        Sentry.capture_exception(service_result.failure || changelog_service_result.failure)
        redirect_to(identity_profile_path)
      end
    end

    private

    def require_mailchimp_configured
      redirect_to(identity_profile_path) unless ETEngine::Mailchimp.enabled?
    end
  end
end
