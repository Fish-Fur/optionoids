# Optionoids
_(Terrible name, I know)_

Optionoids provides a simple, flexible, and concise method of validating option hashes passed to methods. Failures of validation can either raise an error or return an array of the errors. Checks can be chained together to create complex validations, and can be used to validate presence, population, types, and counts.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add optionoids

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install optionoids

## Usage

Optionoids provides two methods on the Hash class. The `expecting` method is used for hard validations that will raise an error if the validation fails, while the `checking` method is used for soft validations that will provide an array of errors if the validation fails.

```ruby
require 'optionoids'

class MyClass
  def my_method(name, options = {})
    expecting = options.expecting.with_params(name: name)
      .only_these(%i[name address age])
    expecting.that(%i[name address]).required.of_type(String)
             .and.that(:age).of_type(Integer)
  end
end
```

## Initialization

To start a hard validation, call `expecting` on the hash you want to validate. This will return an instance of `Optionoids::Checker`.

```ruby
options = { name: 'John', age: 30 }
checker = options.expecting
```

To start a soft validation, call `checking` on the hash you want to validate. This will return an instance of `Optionoids::Checker`.

```ruby
options = { name: 'John', age: 30 }
checker = options.checking
```

Both methods accept a `keys:` argument to specify an initial key filtering state (see below). The keys argument can be a single key or an array of keys.

```ruby
options = { name: 'John', age: 30, email: 'bob@foo.com' }
checker = options.expecting(keys: :name)
# or
checker = options.checking(keys: [:name, :age])
```

### Additional Parameters

In addition to the pairs in the hash, additional pairs can be added for validation with the `with_params` method.

```ruby
options.expecting.with_params(name: 'John', age: 30)
```

## Filtering

The key/value pairs that a check will be performed on can be filtered to only include certain keys. Once a filter is set, all subsequent checks will only be performed on the keys that are in the filter until the filter is altered or cleared. By default, there is no filter set, and all keys in the hash will be checked. An initial filter can be set when the checker is created by passing a `keys:` argument to the `expecting` or `checking` methods.

### `that(keys)` Method

Sets a set of keys that subsequent checks will be performed on.

```ruby
checker = options.expecting.that(%i[name address age])
checker.keys # => [:name, :address, :age]
```

### `plus(keys)` Method

Adds keys to the current filter.

```ruby
checker = options.expecting.that(%i[name address]).plus(:age)
checker.keys # => [:name, :address, :age]
```

### `minus(keys)` Method

Removes keys from the current filter.

```ruby
checker = options.expecting.that(%i[name address age]).minus(:address)
checker.keys # => [:name, :age]
```

### `and` Method

Clears the current filter.

```ruby
expecting = options.expecting.that(%i[name address age])
expecting.that(:name).required.and.that(:age).populated
```

Alias: _`all`_

```ruby
expecting = options.expecting.that(%i[name address age])
expecting.that(:name).required
expecting.all.populated
```

## Checks

Checks are methods that can be chained together to perform validations on the keys and values in the options hash. The checks can be used to validate presence, population, types, and counts. Depending on how the checker was initialized, the checks will either raise an error or add to an array of errors (See `#errors` for accessing the array).

### `only_these(keys)` Method

Checks that only the keys provided are present in the options hash. If any other keys are present, an error will be raised or added to the errors array.

```ruby
expecting = options.expecting.only_these(%i[name address age])
```

Error raised/logged: _Optionoids::Errors::UnexpectedKeys_

### `exist` Method

Checks that all the currently set filter keys are present in the current option Hash. If there are no entries in the current option Hash, an error is raised. If any of the keys are missing, an error is raised.

```ruby
expecting = options.expecting.that(:name).exist
```

Errors raised/logged:
- Empty hash - _Optionoids::Errors::RequiredDataUnavailable_
- Missing keys - _Optionoids::Errors::MissingKeys_

### `populated` Method

Checks that all the filter keys in the hash are not nil or empty. If any of the keys are nil or empty, an error is raised or added to the errors array. It does not error if the keys do not exist in the hash.

```ruby
expecting = options.expecting.that(:name).populated
```

Error raised/logged: _Optionoids::Errors::UnexpectedBlankValue_

Alias: _`all_populated`_

### `blank` Method

Checks that all the filter keys in the hash are nil or empty. If any of the keys are not nil or empty, an error is raised or added to the errors array. It does not error if the keys do not exist in the hash.

```ruby
expecting = options.expecting.that(:name).blank
```

Error raised/logged: _Optionoids::Errors::UnexpectedPopulatedValue_

Alias: _`all_blank`_

### `not_nil_values` Method

Checks that all the filter keys in the hash are not nil. If any of the keys are nil, an error is raised or added to the errors array. It does not error if the keys do not exist in the hash.

```ruby
expecting = options.expecting.that(:name).not_nil_values
```

Error raised/logged: _Optionoids::Errors::UnexpectedNilValue_

### `nil_values` Method

Checks that all the filter keys in the hash are nil. If any of the keys are not nil, an error is raised or added to the errors array. It does not error if the keys do not exist in the hash.

```ruby
expecting = options.expecting.that(:name).nil_values
```

Error raised/logged: _Optionoids::Errors::UnexpectedNotNilValue_

### `one_or_none` Method

Checks that at most one of the filter keys in the hash are present. If more than one of the keys are present, an error is raised or added to the errors array. It does not consider values, only the presence of the keys.

```ruby
expecting = options.expecting.that(%i[name age]).one_or_none
```

Error raised/logged: _Optionoids::Errors::UnexpectedMultipleKeys_

### `just_one` Method

Checks that exactly one of the filter keys in the hash are present. If none or more than one of the keys are present, an error is raised or added to the errors array. It does not consider values, only the presence of the keys.

```ruby
expecting = options.expecting.that(%i[name age]).just_one
```

Errors raised/logged:
- Empty hash - _Optionoids::Errors::RequiredDataUnavailable_
- None or more than one keys - _Optionoids::Errors::UnexpectedMultipleKeys_

### `one_or_more` Method

Checks that at least one of the filter keys in the hash are present. If none of the keys are present, an error is raised or added to the errors array. It does not consider values, only the presence of the keys.

```ruby
expecting = options.expecting.that(%i[name age]).one_or_more
```

Error raised/logged: _Optionoids::Errors::ExpectedMultipleKeys_

### `of_types(types)` Method

Checks that the values of the filter keys in the hash are of the types provided. If any of the values are not of the expected type, an error is raised or added to the errors array. It does not error if the keys do not exist in the hash or if the value is nil.

```ruby
expecting = options.expecting.that(:name).of_types(String, Symbol)
```

Error raised/logged: _Optionoids::Errors::UnexpectedValueType_

Alias: _`of_type`_, _`types`_, _`type`_

### `possible_values(variants)` Method

Checks that the values of the filter keys in the hash are one of the possible values provided. If any of the values are not one of the possible values, an error is raised or added to the errors array. It does not error if the keys do not exist in the hash or if the value is nil.

```ruby
expecting = options.expecting.that(:name).possible_values('John', 'Jane', 'Doe')
```

Error raised/logged: _Optionoids::Errors::UnexpectedValueVariant_

## Convenience Methods

The `Optionoids::Checker` class provides several convenience methods to make it easier to perform common checks. These methods are available on both hard and soft checkers.

### `identifier` Method

Checks that the value of the filter key is a valid identifier. A valid identifier is a populated String or Symbol.

```ruby
expecting = options.expecting.that(:name).identifier
```

Errors raised/logged:
- If the wrong type: _Optionoids::Errors::UnexpectedValueType_
- If the value is nil or empty: _Optionoids::Errors::UnexpectedBlankValue_

### `flag` Method

Checks that the value of the filter key is a populated boolean. A boolean is either `true` or `false`.

```ruby
expecting = options.expecting.that(:active).flag
```

Errors raised/logged:
- If the wrong type: _Optionoids::Errors::UnexpectedValueType_
- If the value is nil or empty: _Optionoids::Errors::UnexpectedBlankValue_

### `required` Method

Checks that the filter key is present and populated in the options hash.

```ruby
expecting = options.expecting.that(:name).required
```

Errors raised/logged:
- If the hash is empty: _Optionoids::Errors::RequiredDataUnavailable_
- Not present: _Optionoids::Errors::MissingKeys_
- If the value is nil or empty: _Optionoids::Errors::UnexpectedBlankValue_

## Soft Errors

If the checker was initialized with `checking`, the errors will be collected in an array. You can access the errors using the `errors` method. A predicate method `failed?` is also available to check if there are any errors.

```ruby
checker = options.checking.that(:name).required
checker.errors # => ["Missing keys: name", "Unexpected blank value for key: name"]
checker.failed? # => true
```

## Data Access / Debugging

### `current_options` Method

Returns the current filtered options Hash that is being checked.

```ruby
checker = options.expecting.that(:name).current_options
# => { name: 'John' }
```

### `global_options` Method

Returns the original options Hash that was passed to the checker. Options added with `with_params` are included in this hash.

```ruby
checker = options.expecting.with_params(name: 'John').global_options
# => { name: 'John', age: 30 }
```

### `keys` Method

Returns the keys that are currently being checked. This is useful to see which keys are in the current filter.

```ruby
checker = options.expecting.that(:name, :age).keys
# => [:name, :age]
```

## Future Enhancements

- Add support for regex checks on values.
- Add common checks using regex (e.g., email, URL).
- Add support for range checks on numeric & date values.
- Implement a similar API for cleaning the options hash.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/optionoids. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/optionoids/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Optionoids project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/optionoids/blob/main/CODE_OF_CONDUCT.md).
