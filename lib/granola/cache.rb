# frozen_string_literal: true

require "granola"

# Adds caching capabilities to Granola serializers. Use the `cache` directive on
# the serializers for this:
#
# Example:
#
#   class PersonSerializer < Granola::Serializer
#     cache key: "person", expires_in: 3600
#
#     def data
#       {}
#     end
#
#     def cache_key
#       [object.id, object.updated_at.to_i].join(":")
#     end
#   end
#
#   serializer = PersonSerializer.new(person)
#   serializer.to_json #=> generates JSON and stores in Granola::Cache.store
#   serializer.to_json #=> retreives the JSON from the cache.
#
#   # do something with person so that `person.updated_at` changes
#
#   serializer.to_json #=> generates JSON and puts the new version in the store
#
# Cache Options
# =============
#
# Granola::Cache only recognizes two options: `:key` and `:store`. Any other
# option passed will be ignored by Granola, but forwarded to the cache store
# (see below.)
#
# `:key`
# ------
#
# This is meant to be a prefix applied to cache keys. In the example above, any
# particular serializer will be stored in the cache with the following key:
#
#   "#{key}/#{object.id}:#{object.updated_at.to_i}"
#
# `:store`
# --------
#
# This allows overriding the caching store for a specific serializer.
#
#   class WeeklyReportSerializer < Granola::Serializer
#     cache store: DifferentStore.new
#   end
#
# See Cache Stores below for more on configuring the global store.
#
# Cache Stores
# ============
#
# By default, Granola::Cache stores cached output from serializers in an
# in-memory Hash. This is not meant for production use. You should provide an
# alternative store for your application.
#
# Alternative stores should implement a single method:
#
#   fetch(key, options = {}, &block)
#
# Where:
#
#   key     - The cache key to fetch from cache.
#   options - Any options the cache store can take (for example, `:expires_in`
#             if your store supports Time-based expiration.)
#
# If the key isn't found in the store, the block is invoked, and the result from
# this block is both returned _and_ stored in the cache for further use.
#
# This is compatible with `ActiveSupport::Cache::Store`, so if you're in a Rails
# application, you can just do this in `config/initializers/granola.rb`:
#
#   Granola::Cache.store = Rails.cache
module Granola::Cache
  class << self
    # Public: Get/Set the Cache store. By default this is an instance of
    # Granola::Cache::MemoryStore. See that class for the expected interface.
    attr_accessor :store
  end

  # MemoryStore just stores things in a Hash in memory. WARNING: MemoryStore is
  # *not* thread safe. It's not meant for production use. You should provide a
  # proper implementation that stores the rendered output somewhere (like redis,
  # memcached, etc)
  class MemoryStore
    def initialize # :nodoc:
      @store = {}
    end

    # Public: Fetch an object from the cache, or, if none is found, yield and
    # store the result of executing the block.
    #
    # key     - A String with the cache key.
    # options - A Hash of options. MemoryStore does not support any options, and
    #           just ignores this argument.
    #
    # Yields and stores the result of evaluating the block on a cache miss.
    # Returns the value stored in the cache.
    def fetch(key, options = {})
      @store.fetch(key) { @store[key] = yield }
    end
  end

  # Extensions to Granola::Serializer to support configuring caching on a
  # serializer-by-serializer basis.
  module CacheableSerializer
    # Public: Make this serializer cacheable. Any unrecognized options will be
    # forwarded to the cache store.
    #
    # options - Hash of options (default: {}):
    #           :key - The prefix to use for keys when storing keys in the
    #                  cache.
    #
    # Returns nothing.
    def cache(options = {})
      cache_options[:should_cache] = true
      cache_options.update(options)
    end

    # Internal: Access the current cache options for this serializer.
    def cache_options
      @cache_options ||= {}
    end

    # Public: Disable caching for the duration of the block.
    def without_caching
      should_cache = cache_options[:should_cache]
      cache_options[:should_cache] = false
      yield
    ensure
      cache_options[:should_cache] = should_cache
    end
  end

  # Extensions to Granola::Renderer to perform the actual storing in or
  # retreiving from the cache.
  module CacheableRenderer
    def render(serializer, *) # :nodoc:
      options = case serializer
                when Granola::List
                  serializer.item_serializer.cache_options
                else
                  serializer.class.cache_options
                end

      options = options.dup

      store = options.delete(:store) { Granola::Cache.store }
      if options.delete(:should_cache)
        key = [options.delete(:key), serializer.cache_key].compact.join("/")
        store.fetch(key, options) { super }
      else
        super
      end
    end
  end
end

Granola::Serializer.extend(Granola::Cache::CacheableSerializer)
Granola::Renderer.prepend(Granola::Cache::CacheableRenderer)
Granola::Cache.store = Granola::Cache::MemoryStore.new
