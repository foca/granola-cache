# frozen_string_literal: true

require "redic"

module Granola
  module Cache
    # Redis-based cache store, relying on Redic for transport.
    #
    # Example:
    #
    #   Granola::Cache.store = Granola::Cache::RedisStore.new($redic)
    class RedisStore
      # Public: Initialize the store.
      #
      # redis - A Redic instance (defaults to `Redic.new`).
      def initialize(redis = Redic.new)
        @redis = redis
      end

      # Public: Fetch/Store a value from the cache.
      #
      # key     - String key under which to store the value.
      # options - Options Hash (defaults to: `{}`):
      #           :expire_in - Integer TTL in seconds for keys to expire.
      #
      # Yields if the key isn't found, and the result of the block is stored in
      #   the cache.
      #
      # Returns a String.
      def fetch(key, options = {})
        value = @redis.call("GET", key)
        return value unless value.nil?

        value = yield

        expiration = ["EX", options[:expire_in]] if options[:expire_in]
        @redis.call("SET", key, value, *expiration)

        value
      end
    end
  end
end
