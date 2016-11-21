# frozen_string_literal: true

require "granola"

module Granola::Cache
  class << self
    attr_accessor :store
  end

  class MemoryStore
    def initialize
      @store = {}
    end

    def fetch(key)
      @store.fetch(key) { @store[key] = yield }
    end
  end

  module CacheableSerializer
    def cache(options = {})
      cache_options[:should_cache] = true
      cache_options.update(options)
    end

    def cache_options
      @cache_options ||= {}
    end
  end

  module CacheableRenderer
    def render(serializer, *)
      options = case serializer
                when Granola::List
                  serializer.item_serializer.cache_options
                else
                  serializer.class.cache_options
                end

      if options.fetch(:should_cache, false)
        key = [options[:key], serializer.cache_key].compact.join("/")
        Granola::Cache.store.fetch(key) { super }
      else
        super
      end
    end
  end
end

Granola::Serializer.extend(Granola::Cache::CacheableSerializer)
Granola::Renderer.prepend(Granola::Cache::CacheableRenderer)
Granola::Cache.store = Granola::Cache::MemoryStore.new
