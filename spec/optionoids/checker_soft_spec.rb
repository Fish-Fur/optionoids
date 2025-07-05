# frozen_string_literal: true

require 'spec_helper'
require 'optionoids/checker'

RSpec.describe Optionoids::Checker do
  let(:instance) { described_class.new({}) }

  describe '#initialize' do
    it 'with options and keys the checker is configured correctly' do
      checker = described_class.new({ a: 1, b: 2 }, keys: [:a], hard: false)
      expect(checker.instance_variable_get(:@options)).to eq({ a: 1, b: 2 })
      expect(checker.instance_variable_get(:@keys)).to eq([:a])
    end

    it 'without keys the current options are the global options' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false)
      expect(checker.global_options).to eq({ a: 1, b: 2 })
      expect(checker.current_options).to eq(checker.global_options)
    end

    it 'with keys the current options are the global options' do
      checker = described_class.new({ a: 1, b: 2 }, keys: [:a], hard: false)
      expect(checker.global_options).to eq({ a: 1, b: 2 })
      expect(checker.current_options).to eq({ a: 1 })
    end
  end

  describe '#keys' do
    it 'returns the keys that are currently being checked' do
      checker = described_class.new({ a: 1, b: 2 }, keys: %i[a b])
      expect(checker.keys).to eq(%i[a b])
    end
  end

  describe '#with_params' do
    it 'with params add to the current options' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).with_params({ c: 3 })
      expect(checker.current_options).to eq({ a: 1, b: 2, c: 3 })
    end

    it 'with params does affect the global options' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).with_params({ c: 3 })
      expect(checker.global_options).to eq({ a: 1, b: 2, c: 3 })
    end

    it 'with params is filtered by the keys' do
      checker = described_class.new({ a: 1, b: 2 }, keys: [:c], hard: false).with_params({ c: 4 })
      expect(checker.current_options).to eq({ c: 4 })
    end

    it 'with params overrides existing keys in the current options' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).with_params({ a: 3 })
      expect(checker.current_options).to eq({ a: 3, b: 2 })
    end
  end

  describe '#and' do
    it 'clears the keys and restores current to global options' do
      checker = described_class.new({ a: 1, b: 2 }, keys: %i[a b], hard: false)
      checker.and
      expect(checker.current_options).to eq({ a: 1, b: 2 })
      expect(checker.instance_variable_get(:@keys)).to eq([])
    end

    it "'all' is an alias for #and" do
      expect(instance).to have_alias(:all).for(:and)
    end
  end

  describe '#that' do
    it 'accepts a single key and filters current options' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).that(:a)
      expect(checker.current_options).to eq({ a: 1 })
    end

    it 'accepts multiple keys and filters current options' do
      checker = described_class.new({ a: 1, b: 2, c: 3 }, hard: false).that(:a, :c)
      expect(checker.current_options).to eq({ a: 1, c: 3 })
    end
  end

  describe '#minus' do
    it 'removes specified key from the current options filter' do
      checker = described_class.new({ a: 1, b: 2, c: 3 }, keys: %i[a b c], hard: false)
      expect(checker.minus(:b).current_options).to eq({ a: 1, c: 3 })
    end

    it 'removes multiple keys from the current options filter' do
      checker = described_class.new({ a: 1, b: 2, c: 3 }, keys: %i[a b c], hard: false)
      expect(checker.minus(:a, :c).current_options).to eq({ b: 2 })
    end
  end

  describe '#plus' do
    it 'adds a single key to the current options filter' do
      checker = described_class.new({ a: 1, b: 2 }, keys: [:a], hard: false)
      expect(checker.plus(:b).current_options).to eq({ a: 1, b: 2 })
      expect(checker.keys).to eq(%i[a b])
    end

    it 'adds multiple keys to the current options filter' do
      checker = described_class.new({ a: 1, b: 2, c: 3 }, keys: [:a], hard: false)
      expect(checker.plus(:b, :c).current_options).to eq({ a: 1, b: 2, c: 3 })
    end
  end

  describe '#only_these' do
    it 'does not raise an error when all keys are expected' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false)
      expect { checker.only_these(%i[a b]) }.not_to raise_error
    end

    it 'raises an error when unexpected keys are present' do
      checker = described_class.new({ a: 1, b: 2, c: 3 }, hard: false).only_these(%i[a b])
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedKeys))
    end

    it 'does not raise an error when not all possible keys are included' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).only_these(%i[a b c])
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedKeys))
    end
  end

  describe '#exist' do
    it 'does not raise an error when all keys are present' do
      checker = described_class.new({ a: 1, b: 2 }, keys: %i[a b], hard: false).exist
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::MissingKeys))
    end

    it 'raises an error when a key is missing' do
      checker = described_class.new({ a: 1 }, keys: %i[a b], hard: false).exist
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::MissingKeys))
    end

    it 'raises an error when no keys are specified' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).exist
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::RequiredDataUnavailable))
    end
  end

  describe '#populated' do
    it 'does not raise an error when all values are present' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).populated
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedBlankValue))
    end

    it 'raises an error when a value is blank' do
      checker = described_class.new({ a: 1, b: nil }, hard: false).populated
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedBlankValue))
    end

    it "'all_populated' is an alias for 'populated'" do
      expect(instance).to have_alias(:all_populated).for(:populated)
    end
  end

  describe '#blank?' do
    it 'does not raise an error when all values are blank' do
      checker = described_class.new({ a: nil, b: nil }, hard: false).blank
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedPopulatedValue))
    end

    it 'raises an error when a value is present' do
      checker = described_class.new({ a: nil, b: 2 }, hard: false).blank
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedPopulatedValue))
    end

    it "'all_blank' is an alias for 'blank'" do
      expect(instance).to have_alias(:all_blank).for(:blank)
    end
  end

  describe '#nil_values' do
    it 'does not raise an error when all values are nil' do
      checker = described_class.new({ a: nil, b: nil }, hard: false).nil_values
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedNonNilValue))
    end

    it 'raises an error when a value is not nil' do
      checker = described_class.new({ a: nil, b: '' }, hard: false).nil_values
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedNonNilValue))
    end
  end

  describe '#not_nil_values' do
    it 'does not raise an error when all values are not nil' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).not_nil_values
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedNilValue))
    end

    it 'raises an error when a value is nil' do
      checker = described_class.new({ a: 1, b: nil }, hard: false).not_nil_values
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedNilValue))
    end
  end

  describe '#one_or_none' do
    it 'does not raise an error when only one key is present' do
      checker = described_class.new({ a: 1 }, keys: [:a], hard: false).one_or_none
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedMultipleKeys))
    end

    it 'raises an error when multiple keys are present' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).one_or_none
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedMultipleKeys))
    end

    it 'does not raise an error when no keys are present' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).that(:c).one_or_none
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedMultipleKeys))
    end
  end

  describe '#just_one' do
    it 'does not raise an error when one key is present' do
      checker = described_class.new({ a: 1, b: 2 }, keys: [:a], hard: false).just_one
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::RequiredDataUnavailable))
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedMultipleKeys))
    end

    it 'raises an error when no keys are present' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).that(:c).just_one
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::RequiredDataUnavailable))
    end

    it 'raises an error when multiple keys are present' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).just_one
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedMultipleKeys))
    end
  end

  describe '#one_of_more' do
    it 'does not raise an error when one key is present' do
      checker = described_class.new({ a: 1, b: 2 }, keys: [:a], hard: false).one_of_more
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::ExpectedMultipleKeys))
    end

    it 'does not raise an error when multiple keys are present' do
      checker = described_class.new({ a: 1, b: 2 }, hard: false).one_of_more
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::ExpectedMultipleKeys))
    end

    it 'raises an error when no keys are present' do
      checker = described_class.new({}, hard: false).one_of_more
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::ExpectedMultipleKeys))
    end
  end

  describe '#of_types' do
    it 'does not raise an error when all values are of the specified types' do
      checker = described_class.new({ a: 1, b: 'test' }, hard: false).of_types(Integer, String)
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedValueType))
    end

    it 'raises an error when a value is not of the specified types' do
      checker = described_class.new({ a: 1, b: [] }, hard: false).of_types(Integer, String)
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedValueType))
    end

    it 'do not raise an error if a value is nil but others are of the specified types' do
      checker = described_class.new({ a: 1, b: nil }, hard: false).of_types(Integer, String)
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedValueType))
    end

    it 'do not rails an error if all values are nil' do
      checker = described_class.new({ a: nil, b: nil }, hard: false).of_types(Integer, String)
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedValueType))
    end

    it 'do not raise an error if there are no values' do
      checker = described_class.new({ a: 1, b: nil }, hard: false).that(:c).of_types(Integer)
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedValueType))
    end

    it "'of_type' is an alias for 'of_types'" do
      expect(instance).to have_alias(:of_type).for(:of_types)
    end

    it "'types' is an alias for 'of_types'" do
      expect(instance).to have_alias(:types).for(:of_types)
    end

    it "'type' is an alias for 'of_types'" do
      expect(instance).to have_alias(:type).for(:of_types)
    end
  end

  describe '#possible_values' do
    it 'does not raise an error when all values match one of a set of variants' do
      checker = described_class.new({ a: :foo, b: :bar }, hard: false).possible_values(%i[foo bar])
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedValueVariant))
    end

    it 'raises an error when a value does not match any of the variants' do
      checker = described_class.new({ a: :foo, b: :baz }, hard: false).possible_values(%i[foo bar])
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedValueVariant))
    end

    it 'does not raise an error if a value is nil but others match the variants' do
      checker = described_class.new({ a: :foo, b: nil }, hard: false).possible_values(%i[foo bar])
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedValueVariant))
    end

    it 'does not raise an error if all values are nil' do
      checker = described_class.new({ a: nil, b: nil }, hard: false).possible_values(%i[foo bar])
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedValueVariant))
    end
  end

  describe '#identifier' do
    it 'does not raise an error when all values are Strings or Symbols and not blank' do
      checker = described_class.new({ a: 'test', b: :example }, hard: false).identifier
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedValueType))
    end

    it 'raises an error when a value is not a String or Symbol' do
      checker = described_class.new({ a: 'test', b: 123 }, hard: false).identifier
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedValueType))
    end

    it 'raises an error when a value is blank' do
      checker = described_class.new({ a: '', b: :example }, hard: false).identifier
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedBlankValue))
    end
  end

  describe '#flag' do
    it 'does not raise an error when all values are TrueClass or FalseClass and not blank' do
      checker = described_class.new({ a: true, b: false }, hard: false).flag
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedValueType))
    end

    it 'raises an error when a value is not TrueClass or FalseClass' do
      checker = described_class.new({ a: true, b: 123 }, hard: false).flag
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedValueType))
    end

    it 'raises an error when a value is blank' do
      checker = described_class.new({ a: nil, b: false }, hard: false).flag
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedNilValue))
    end
  end

  describe '#required' do
    it 'does not raise an error when all keys are present and populated' do
      checker = described_class.new({ a: 1, b: 2 }, keys: %i[a b], hard: false).required
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::MissingKeys))
      expect(checker.errors).not_to include(an_instance_of(Optionoids::Errors::UnexpectedBlankValue))
    end

    it 'raises an error when a key is missing' do
      checker = described_class.new({ a: 1 }, keys: %i[a b], hard: false).required
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::MissingKeys))
    end

    it 'raises an error when a value is blank' do
      checker = described_class.new({ a: 1, b: nil }, keys: %i[a b], hard: false).required
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedBlankValue))
    end
  end

  describe 'multiple checks' do
    it 'can chain multiple checks together' do
      checker = described_class.new({ a: 1, b: nil }, hard: false).populated.of_type(String)
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedValueType))
      expect(checker.errors).to include(an_instance_of(Optionoids::Errors::UnexpectedBlankValue))
    end
  end
end
