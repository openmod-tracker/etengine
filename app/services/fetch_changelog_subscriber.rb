# frozen_string_literal: true

class FetchChangelogSubscriber
  include Dry::Monads[:result, :maybe]

  def call(email:)
    subscriber = ETEngine::Mailchimp.fetch_subscriber(email, Settings.mailchimp.changelog_list_url)
    Success(Maybe(subscriber))
  rescue Faraday::ResourceNotFound
    Success(None())
  rescue Faraday::Error => e
    Failure(e)
  end
end
