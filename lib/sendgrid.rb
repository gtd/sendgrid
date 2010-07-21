require 'json'
require 'sendgrid/wrappers'

module SendGrid
  include SendGrid::Wrappers

  VALID_OPTIONS = [
    :opentrack,
    :clicktrack,
    :ganalytics,
    :gravatar,
    :subscriptiontrack,
    :footer,
    :spamcheck,
    :bypass_list_management
  ]

  def self.included(base)
    base.class_eval do
      class << self
        attr_accessor :default_sg_category
        attr_writer :default_sg_settings
      end
      attr_accessor :sg_category, :sg_recipients, :sg_substitutions
      attr_writer :sg_settings
    end
    base.extend(ClassMethods)
  end

  module ClassMethods
    include SendGrid::Wrappers

    # Sets a default category for all emails.
    # :use_subject_lines has special behavior that uses the subject-line of
    # each outgoing email for the SendGrid category. This special behavior
    # can still be overridden by calling sendgrid_category from within a
    # mailer method.
    def sendgrid_category(category)
      self.default_sg_category = category
    end

    def sendgrid_settings(option, settings)
      if VALID_OPTIONS.include?(option)
        self.default_sg_settings[option] ||= {}
        self.default_sg_settings[option].merge!(settings)
      end
    end

    def default_sg_settings
      @default_sg_settings ||= {}
    end
  end

  # Call within mailer method to override the default value.
  def sendgrid_category(category)
    @sg_category = category
  end

  # Call within mailer method to add an array of recipients
  def sendgrid_recipients(emails)
    @sg_recipients = Array.new unless @sg_recipients
    @sg_recipients = emails
  end

  # Call within mailer method to add an array of substitions
  # NOTE: you must ensure that the length of the substitions equals the
  #       length of the sendgrid_recipients.
  def sendgrid_substitute(placeholder, subs)
    @sg_substitutions = Hash.new unless @sg_substitutions
    @sg_substitutions[placeholder] = subs
  end

  def sendgrid_settings(option, settings)
    if VALID_OPTIONS.include?(option)
      sg_settings[option] ||= {}
      sg_settings[option].merge!(settings)
    end
  end

  def sg_settings
    @sg_settings ||= {}
  end

  # Unique Args for Email Callback
  def sendgrid_unique_args(val)
    @sg_unique_args ||= {}
    @sg_unique_args.merge!(val) if val.is_a?(Hash)
  end

  # Sets the custom X-SMTPAPI header after creating the email but before delivery
  def create!(method_name, *parameters)
    super
    if @sg_substitutions && !@sg_substitutions.empty?
      @sg_substitutions.each do |find, replace|
        raise ArgumentError.new("Array for #{find} is not the same size as the recipient array") if replace.size != @sg_recipients.size
      end
    end
    puts "SendGrid X-SMTPAPI: #{sendgrid_json_headers(mail)}" if Object.const_defined?("SENDGRID_DEBUG_OUTPUT") && SENDGRID_DEBUG_OUTPUT
    @mail['X-SMTPAPI'] = sendgrid_json_headers(mail)
  end

  private

  # Take all of the options and turn it into the json format that SendGrid expects
  def sendgrid_json_headers(mail)
    header_opts = {}

    # Set category
    if @sg_category && @sg_category == :use_subject_lines
      header_opts[:category] = mail.subject
    elsif @sg_category
      header_opts[:category] = @sg_category
    elsif self.class.default_sg_category && self.class.default_sg_category.to_sym == :use_subject_lines
      header_opts[:category] = mail.subject
    elsif self.class.default_sg_category
      header_opts[:category] = self.class.default_sg_category
    end

    # Set multi-recipients
    if @sg_recipients && !@sg_recipients.empty?
      header_opts[:to] = @sg_recipients
    end

    # Set custom substitions
    if @sg_substitutions && !@sg_substitutions.empty?
      header_opts[:sub] = @sg_substitutions
    end

    # Set unique args for event callbacks
    if @sg_unique_args && !@sg_unique_args.empty?
      header_opts[:unique_args] = @sg_unique_args
    end

    # Set enables/disables
    header_opts[:filters] = {} unless header_opts.has_key?(:filters)
    header_opts[:filters].merge!(filters_hash_from_settings)

    header_opts.to_json.gsub(/(["\]}])([,:])(["\[{])/, '\\1\\2 \\3')
  end

  def filters_hash_from_settings
    opts = self.class.default_sg_settings.keys + sg_settings.keys
    filters = {}

    opts.uniq.each do |option|
      opt = option.to_sym
      defaults = self.class.default_sg_settings[opt] || {}
      settings = defaults.merge(sg_settings[opt] || {})
      filters[opt] = { :settings => settings } unless settings.empty?
    end

    return filters
  end
end
