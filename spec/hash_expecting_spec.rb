# frozen_string_literal: true

require 'spec_helper'
require 'hash_expecting'

RSpec.describe Hash do
  describe '#expecting' do
    it 'returns an instance of Checker' do
      expect({}.expecting).to be_a(Optionoids::Checker)
    end

    it 'returned checker is for hard checks' do
      expect({}.expecting.hard).to be(true)
    end
  end

  describe '#checking' do
    it 'returns an instance of Checker' do
      expect({}.checking).to be_a(Optionoids::Checker)
    end

    it 'returned checker is for soft checks' do
      expect({}.checking.hard).to be(false)
    end
  end
end
