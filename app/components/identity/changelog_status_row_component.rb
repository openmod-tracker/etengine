module Identity
  class ChangelogStatusRowComponent < ApplicationComponent
    include ButtonHelper

    def initialize(changelog_subscribed:)
      @changelog_subscribed = changelog_subscribed
    end
  end
end
