# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'hash_expecting'
require 'optionoids/errors'

module Optionoids
  # Class to wrap an options Hash and perform checks on the keys and values.  All method return
  # the same instance of the Checker, allowing for method chaining.
  class Checker
    attr_reader :hard, :keys

    # @param options [Hash] The options Hash to check against.
    # @param keys [Array<String, Symbol>] The keys to initially check in the options Hash. If nil,
    #                            all keys are checked.
    def initialize(options, keys: nil, hard: true)
      @options = options
      @keys = [keys].flatten.compact
      @params = {}
      @hard = hard
      clip_options
    end

    # A set of additional options to check against.  This is useful for checking other none optional
    # parameters that are not part of the options Hash.
    def with_params(params)
      @params = params.is_a?(Hash) ? params : params.to_h
      clip_options
      self
    end

    # Returns the current 'filtered' option Hash.
    def current_options
      @clipped_options
    end

    # Returns the 'unfiltered' options Hash.
    def global_options
      @options.merge(@params)
    end

    ## FILTERING ##

    # Removes all option Hash filtering.
    def and
      @keys = []
      clip_options
      self
    end

    alias all and

    # Add a key set filter to the current option Hash.  The keys provided do not have to exist in the
    # option Hash, but only those that do will be checked.  Filters are not cumulative, so calling
    # this method will replace any previous key filters.
    def that(*keys)
      @keys = keys.flatten.compact
      clip_options
      self
    end

    # Removes the keys from the current option Hash filter.  No error will be raised if the given
    # keys are not present in the current option Hash.
    def minus(*keys)
      @keys -= keys
      clip_options
      self
    end

    # Adds the given keys to the current option Hash filter.  No error will be raised if the given
    # keys are not present in the current option Hash.
    def plus(*keys)
      @keys |= keys.flatten.compact.uniq
      clip_options
      self
    end

    ## KEY PRESENCE CHECKS ##

    # Checks that the current option Hash contains only the given keys.  If any unexpected keys are
    # present, an error is raised.  If no keys are given, the current option Hash is not checked.
    # Error: Optionoids::Errors::UnexpectedKeys
    def only_these(keys)
      unexpected_keys = @clipped_options.keys - [keys].flatten
      _error_or_log(Errors::UnexpectedKeys.new(nil, keys: unexpected_keys)) if unexpected_keys.any?

      self
    end

    # Checks that all the currently set filter keys are present in the current option Hash.  If there
    # are no entries in the current option Hash an error (Optionoids::Errors::RequiredDataUnavailable)
    # is raised.  If any of the keys are missing, an error (Optionoids::Errors::MissingKeys) is raised.
    def exist
      return _error_or_log(Errors::RequiredDataUnavailable.new(nil, check: 'present')) if @keys.empty?

      missing_keys = @keys - @clipped_options.keys
      return self if missing_keys.empty?

      _error_or_log(Errors::MissingKeys.new(nil, keys: missing_keys))
    end

    ## VALUE POPULATION CHECKS ##

    # Checks that the current option Hash entries all have non-blank values.  If any of the values
    # are blank, an error (Optionoids::Errors::UnexpectedBlankValue) is raised.
    def populated
      _error_on_check(:blank?, Errors::UnexpectedBlankValue)
      self
    end

    alias all_populated populated

    # Checks that the current option Hash entries all have blank values.  If any of the values are
    # populated, an error (Optionoids::Errors::UnexpectedPopulatedValue) is raised.
    def blank
      _error_on_check(:present?, Errors::UnexpectedPopulatedValue)
      self
    end

    alias all_blank blank

    # Checks that the current option Hash entries all have non-nil values.  If any of the values are
    # nil, an error (Optionoids::Errors::UnexpectedNilValue) is raised.
    def not_nil_values
      _error_on_check(:nil?, Errors::UnexpectedNilValue)
      self
    end

    # Checks that the current option Hash entries all have nil values.  If any of the values are
    # not nil, an error (Optionoids::Errors::UnexpectedNonNilValue) is raised.
    def nil_values
      failed_keys = @clipped_options.compact.keys
      return self if failed_keys.empty?

      _error_or_log(Errors::UnexpectedNonNilValue.new(nil, keys: failed_keys))
    end

    ## KEY COUNT CHECKS ##

    # Checks that the current option Hash contains no more that one key.  If more than one  key id
    # present, an error (Optionoids::Errors::UnexpectedMultipleKeys) is raised.  If there are no keys
    # present, no error is raised.
    def one_or_none
      msg = "Expected a maximum or one key, but found: #{@clipped_options.keys.to_sentence}"
      _error_or_log(Errors::UnexpectedMultipleKeys.new(msg, keys: @clipped_options.keys)) if @clipped_options.count > 1

      self
    end

    # Checks that the current option Hash contains exactly one key.  If no keys are present, an error
    # (Optionoids::Errors::RequiredDataUnavailable) is raised.  If more than one key is present, an error
    # (Optionoids::Errors::UnexpectedMultipleKeys) is raised.
    def just_one
      _error_or_log(Errors::RequiredDataUnavailable.new(nil, check: 'one_required')) if @clipped_options.empty?
      return self if @clipped_options.one?

      msg = "Expected exactly one key, but found: #{@clipped_options.keys.to_sentence}"
      _error_or_log(Errors::UnexpectedMultipleKeys.new(msg, keys: @clipped_options.keys))
    end

    # Checks that the current option Hash contains one or more keys.  If no keys are present, an error
    # (Optionoids::Errors::ExpectedMultipleKeys).
    def one_of_more
      return self if @clipped_options.count >= 1

      _error_or_log(Errors::ExpectedMultipleKeys.new)
    end

    ## TYPE CHECKS ##

    # Checks that the current option Hash entries are of the given types.  If any of the values are
    # not of the given types, an error (Optionoids::Errors::UnexpectedValueType) is raised. 'nil'
    # values are ignored in the type check.
    def of_types(*types)
      pairs = @clipped_options.compact.select { |_k, v| types.none? { |t| v.is_a?(t) } }
      return self if pairs.empty?

      _error_or_log(Errors::UnexpectedValueType.new(nil, keys: pairs.keys, types: types.map(&:name)))
    end

    alias of_type of_types
    alias types of_types
    alias type of_types

    ## VALUE CHECKS ##

    # Checks that the current option Hash entries are one of the given variants.  If any of the
    # values are not one of the given variants, an error (Optionoids::Errors::UnexpectedValueVariant).
    # If a value is nil it is ignored in the check.
    def possible_values(variants)
      pairs = @clipped_options.compact.select { |_k, v| variants.none? { |variant| v == variant } }
      return self if pairs.empty?

      _error_or_log(Errors::UnexpectedValueVariant.new(nil, keys: pairs.keys, variants: variants))
    end

    ## COMPOSITE CHECKS ##

    # Checks that the current option Hash entries are usable as identifiers.  This means that the
    # values are either Strings or Symbols and are not blank.
    def identifier
      of_type(String, Symbol).populated
    end

    # Checks that the current option Hash entries are usable as flags.  This means that the values
    # are either TrueClass or FalseClass and are not blank.
    def flag
      # Populated check mist use not nil because false is never 'present?'
      of_type(TrueClass, FalseClass).not_nil_values
    end

    # Checks that the current option Hash entries ate both present and populated.
    def required
      exist.populated
    end

    ## SOFT ERROR HANDLING ##

    def errors
      @errors ||= []
    end

    def failed?
      errors.any?
    end

    private

    def _error_or_log(error)
      raise error if @hard

      errors << error
      self
    end

    def _error_on_check(check, error_class)
      failed_keys = _keys_for_check(check)
      return if failed_keys.empty?

      _error_or_log(error_class.new(nil, keys: failed_keys))
    end

    def _keys_for_check(check)
      @clipped_options.select { |_k, v| v.send(check) }.to_h.keys
    end

    def clip_options
      @clipped_options = @options.merge(@params)
      return if @keys.empty?

      @clipped_options = @clipped_options.slice(*@keys)
    end
  end
end
