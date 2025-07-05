# frozen_string_literal: true

# Extends the Hash class to support optionoid option parsing.
class Hash
  # Perform hard checking on the Hash. Hard checking will raise an error if the Hash does not
  # conform to the expectations.
  def expecting(keys = nil)
    Optionoids::Checker.new(self, keys: keys)
  end

  # Perform soft checking on the Hash.  Soft checking will not raise an error.  Errors are logged
  # and can be checked with errors and failed? methods.
  def checking(keys = nil)
    Optionoids::Checker.new(self, keys: keys, hard: false)
  end
end
