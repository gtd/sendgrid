module SendGrid
  module Wrappers
    # Sets the default text for subscription tracking (must be enabled).
    # There are two options:
    # 1. Add an unsubscribe link at the bottom of the email
    #   {:html => "Unsubscribe <% here %>", :plain => "Unsubscribe here: <% %>"}
    # 2. Replace given text with the unsubscribe link
    #   {:replace => "<unsubscribe_link>" }
    def sendgrid_subscriptiontrack_text(texts)
      sendgrid_settings(:subscriptiontrack, {
        :'text/html' => texts[:html],
        :'text/plain' => texts[:plain],
        :replace => texts[:replace]
      })
    end

    # Sets the default footer text (must be enabled).
    # Should be a hash containing the html/plain text versions:
    #   {:html => "html version", :plain => "plan text version"}
    def sendgrid_footer_text(texts)
      sendgrid_settings(:footer, {
        :'text/html' => texts[:html],
        :'text/plain' => texts[:plain]
      })
    end

    # Sets the default spamcheck score text (must be enabled).
    def sendgrid_spamcheck_maxscore(score)
      sendgrid_settings(:spamcheck, :maxscore => score)
    end

    # Enables or disables option for emails.
    # See documentation for details.
    #
    # Supported options:
    # * :opentrack
    # * :clicktrack
    # * :ganalytics
    # * :gravatar
    # * :subscriptiontrack
    # * :footer
    # * :spamcheck

    def sendgrid_enable(*options)
      options.each { |option| sendgrid_settings(option, :enabled => 1) }
    end

    def sendgrid_disable(*options)
      options.each { |option| sendgrid_settings(option, :enabled => 0) }
    end
  end
end