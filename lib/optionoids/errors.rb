# frozen_string_literal: true

require 'active_support/core_ext/array/conversions'

module Optionoids
  # Errors module contains custom error classes for the Optionoids library.
  module Errors
    # Custom error class to indicate that a checker requires keys in #keys or key/values in the
    # current option Hash, but none were provided.
    class RequiredDataUnavailable < StandardError
      attr_reader :check

      def initialize(message = nil, check: nil)
        msg = message || "Required data is unavailable for the check '#{check}'"
        @check = check
        super(msg)
      end
    end

    # Custom error class to indicate the expected keys are not present in the current option Hash
    class MissingKeys < StandardError
      attr_reader :keys

      def initialize(message = nil, keys: [])
        @keys = keys
        msg = message || "Missing required keys: #{keys.to_sentence}"
        super(msg)
      end
    end

    # Custom error class to indicate that unexpected keys are in the current option Hash
    class UnexpectedKeys < StandardError
      attr_reader :keys

      def initialize(message = nil, keys: [])
        @keys = keys
        msg = message || "Unexpected keys found: #{keys.to_sentence}"
        super(msg)
      end
    end

    # Custom error class to indicate that some values ate unexpectedly blank or nil
    class UnexpectedBlankValue < StandardError
      attr_reader :keys

      def initialize(message = nil, keys: [])
        @keys = keys
        msg = message || "Unexpected blank values for keys: #{keys.to_sentence}"
        super(msg)
      end
    end

    # Custom error class to indicate that some values are unexpectedly populated (not blank)
    class UnexpectedPopulatedValue < StandardError
      attr_reader :keys

      def initialize(message = nil, keys: [])
        @keys = keys
        msg = message || "Unexpected populated values for keys: #{keys.to_sentence}"
        super(msg)
      end
    end

    # Custom error class to indicate that some values are unexpectedly not nil
    class UnexpectedNonNilValue < StandardError
      attr_reader :keys

      def initialize(message = nil, keys: [])
        @keys = keys
        msg = message || "Unexpected non-nil values for keys: #{keys.to_sentence}"
        super(msg)
      end
    end

    # Custom error class to indicate that some values are unexpectedly nil
    class UnexpectedNilValue < StandardError
      attr_reader :keys

      def initialize(message = nil, keys: [])
        @keys = keys
        msg = message || "Unexpected nil values for keys: #{keys.to_sentence}"
        super(msg)
      end
    end

    # Custom error class to indicate that only one key is expected, but multiple keys are present
    class UnexpectedMultipleKeys < StandardError
      attr_reader :keys

      def initialize(message = nil, keys: [])
        @keys = keys
        msg = message || "Multiple keys present when only one is expected: #{keys.to_sentence}"
        super(msg)
      end
    end

    # Custom error class to indicate that the values for the keys are not of the expected types
    class UnexpectedValueType < StandardError
      attr_reader :keys, :types

      def initialize(message = nil, keys: [], types: [])
        @keys = keys
        @types = types
        msg = message || "Unexpected value types for keys: #{keys.to_sentence}. " \
                         "Expected types: #{types.to_sentence}"
        super(msg)
      end
    end

    # Custom error class to indicate that a values in the current option Hash are not of the
    # expected variants
    class UnexpectedValueVariant < StandardError
      attr_reader :keys, :variants

      def initialize(message = nil, keys: [], variants: [])
        @keys = keys
        @variants = variants
        msg = message || "Unexpected value variants for keys: #{keys.to_sentence}. " \
                         "Expected variants: #{variants.to_sentence}"
        super(msg)
      end
    end

    # Custom error class to indicate that a checker expected multiple keys but none were provided
    class ExpectedMultipleKeys < StandardError
      def initialize(message = nil)
        msg = message || 'Expected multiple keys but none were provided'
        super(msg)
      end
    end
  end
end
