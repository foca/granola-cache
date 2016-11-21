# frozen_string_literal: true

require "time"

class CacheableSerializer < BaseSerializer
  cache

  def cache_key
    "%s:%s" % [object.id, object.updated_at.to_i]
  end
end

# Reset cache options between tests
DEFAULT_OPTIONS = CacheableSerializer.cache_options
prepare do
  CacheableSerializer.cache_options.clear
  CacheableSerializer.cache_options.update(DEFAULT_OPTIONS)
end

prepare do
  @person = Person.new(1, "Jane Doe", Time.parse("2016-11-20 23:00:00"))
end

setup do
  CacheableSerializer.new(@person)
end

test "considers the cache key's prefix" do |serializer|
  store = Granola::Cache.store.instance_variable_get(:@store)

  serializer.class.cache key: "person"
  result = serializer.to_json

  assert_equal result, store["person/#{serializer.cache_key}"]
  assert_equal nil, store[serializer.cache_key]
end
