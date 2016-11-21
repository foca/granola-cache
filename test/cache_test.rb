# frozen_string_literal: true

require "time"

class CacheableSerializer < BaseSerializer
  cache

  def cache_key
    "%s:%s" % [object.id, object.updated_at.to_i]
  end
end

test "serializers with the cache directive have :should_cache option" do
  assert_equal true, CacheableSerializer.cache_options[:should_cache]
  assert_equal nil, BaseSerializer.cache_options[:should_cache]
end

scope do
  prepare do
    @person = Person.new(1, "Jane Doe", Time.parse("2016-11-20 23:00:00"))
  end

  setup do
    CacheableSerializer.new(@person)
  end

  test "rendering a serializer stores the result in the cache" do |serializer|
    store = Granola::Cache.store.instance_variable_get(:@store)

    cache_key = serializer.cache_key
    assert !store.key?(cache_key)

    result = serializer.to_json
    assert_equal result, store[cache_key]
  end

  test "rendering a cached serializer does so from the store" do |serializer|
    store = Granola::Cache.store = CounterStore.new

    assert_equal 0, store.rendered
    assert_equal 0, store.from_cache

    serializer.to_json

    assert_equal 1, store.rendered
    assert_equal 0, store.from_cache

    serializer.to_json

    assert_equal 1, store.rendered
    assert_equal 1, store.from_cache

    serializer.to_json

    assert_equal 1, store.rendered
    assert_equal 2, store.from_cache
  end

  test "invalidating the key" do |serializer|
    store = Granola::Cache.store = CounterStore.new

    assert_equal 0, store.rendered
    assert_equal 0, store.from_cache

    serializer.to_json

    assert_equal 1, store.rendered
    assert_equal 0, store.from_cache

    @person.updated_at = Time.parse("2016-11-20 23:05:00")

    serializer.to_json

    assert_equal 2, store.rendered
    assert_equal 0, store.from_cache
  end
end
