# frozen_string_literal: true

class DeleteChangelogSubscription
  include Dry::Monads[:result]

  def call(user:)
    ETEngine::Mailchimp.client(Settings.mailchimp.changelog_list_url).patch(
      "members/#{ETEngine::Mailchimp.subscriber_id(user.email)}",
      status: 'unsubscribed'
    )

    Success()
  rescue Faraday::ResourceNotFound
    Success()
  rescue Faraday::Error => e
    Failure(e)
  end
end
