# Granola::Cache [![Build Status](https://img.shields.io/travis/foca/granola-cache.svg)](https://travis-ci.org/foca/granola-cache) [![RubyGem](https://img.shields.io/gem/v/granola-cache.svg)](https://rubygems.org/gems/granola-cache)

Provide caching options for the result of your [Granola][] serializers.

[Granola]: https://github.com/foca/granola

## Example

``` ruby
class PersonSerializer < Granola::Serializer
  cache key: "person", expire_in: 3600

  def data
    {
      id: object.id,
      name: object.name,
    }
  end

  def cache_key
    "%s:%s" % [object.id, object.updated_at.to_i]
  end
end

serializer = PersonSerializer.new(person)
serializer.to_json # Generates JSON and stores it in the cache.
serializer.to_json # Retreives from cache without rendering.

person.update(...) # Do something that would change the `cache_key` (e.g. update
                   # the object's `updated_at`.)

serializer.to_json # Generates JSON again, storing the new version in the cache.
```

**NOTE**: Changing the cache key will invalidate previous versions of the cached
object, but will _not_ delete them from the cache store.

## Install

    gem install granola-cache

## Cache Stores

By default, Granola::Cache stores cached output from serializers in an in-memory
Hash. This is not meant for production use. You should provide an alternative
store for your application.

Alternative stores should implement a single method:

``` ruby
fetch(key, options = {}, &block)
```

Where:

* `key`: The cache key to fetch from cache.
* `options`: Any options the cache store can take (for example, `:expire_in`
  if your store supports Time-based expiration.)

If the key isn't found in the store, the block is invoked, and the result from
this block is both returned _and_ stored in the cache for further use.

There's an example [Redis Store](./examples/redis_store.rb) included in this
repository, should you wish to inspect it.

### Rails

This is compatible with `ActiveSupport::Cache::Store`, so if you're in a Rails
application, you can just do this in `config/initializers/granola.rb`:

``` ruby
Granola::Cache.store = Rails.cache
```

## Cache Options

Pass caching options to a serializer by calling the `cache` singleton method.

Granola::Cache only recognizes these options: `:key` and `:store`. Any other
option passed will be ignored by Granola, but forwarded to the [cache
store](#cache-stores).

### `:key`

This is meant to be a prefix applied to cache keys. In the example above, any
particular serializer will be stored in the cache with the following key:

``` ruby
"#{key}/#{object.id}:#{object.updated_at.to_i}"
```

### `:store`

This allows overriding the caching store for a specific serializer.

``` ruby
class WeeklyReportSerializer < Granola::Serializer
  cache store: DifferentStore.new
end
```

See [Cache Stores](#cache-stores) for more on configuring the global store.

## License

This project is shared under the MIT license. See the attached [LICENSE][] file
for details.

[LICENSE]: ./LICENSE
