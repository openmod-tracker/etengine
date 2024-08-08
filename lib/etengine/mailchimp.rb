# frozen_string_literal: true

module ETEngine
  # Mailchimp is a module which provides a client for the Mailchimp API.
  module Mailchimp
    module_function

    def enabled?
      Settings.dig(:mailchimp, :list_url).present? && Settings.dig(:mailchimp, :api_key).present?
    end

    def client(list_url = Settings.mailchimp.list_url)
      unless enabled?
        raise "Mailchimp is not configured. Please set the 'mailchimp.list_url' and " \
              "'mailchimp.api_key' settings."
      end

      Faraday.new(list_url) do |conn|
        conn.request(:authorization, :basic, '', Settings.mailchimp.api_key)
        conn.request(:json)
        conn.response(:json)
        conn.response(:raise_error)
      end
    end

    def subscriber_id(email)
      Digest::MD5.hexdigest(email.downcase)
    end

    # Fetches the subscriber information if it exists. Raises Faraday::ResourceNotFound if the
    # subscriber does not exist.
    def fetch_subscriber(email, list_url = Settings.mailchimp.list_url)
      client(list_url).get("members/#{subscriber_id(email)}").body
    end

    # Returns if the e-mail address is subscribed to the newsletter.
    def subscribed?(email)
      %w[pending subscribed].include?(fetch_subscriber(email)['status'])
    rescue Faraday::ResourceNotFound
      false
    end

    # Returns if the e-mail address is subscribed to the changelog.
    def changelog_subscribed?(email)
      %w[pending subscribed].include?(fetch_subscriber(email, Settings.mailchimp.changelog_list_url)['status'])
    rescue Faraday::ResourceNotFound
      false
    end

    # Subscribes an e-mail address to the newsletter.
    def subscribe(email)
      client.put("members/#{subscriber_id(email)}", { email_address: email, status: 'subscribed' })
    end

    # Subscribes an e-mail address to the changelog.
    def changelog_subscribe(email)
      client(Settings.mailchimp.changelog_list_url).put("members/#{subscriber_id(email)}", { email_address: email, status: 'subscribed' })
    end

    # Unsubscribes an e-mail address from the newsletter.
    def unsubscribe(email)
      client.put("members/#{subscriber_id(email)}", { email_address: email, status: 'unsubscribed' })
    end

    # Unsubscribes an e-mail address from the changelog.
    def changelog_unsubscribe(email)
      client(Settings.mailchimp.changelog_list_url).put("members/#{subscriber_id(email)}", { email_address: email, status: 'unsubscribed' })
    end
  end
end
