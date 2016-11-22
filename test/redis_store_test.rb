require_relative "../examples/redis_store"
require "time"

prepare { Granola::Cache.store = Granola::Cache::RedisStore.new }
$redis = Redic.new

class CacheableSerializer < BaseSerializer
  cache expire_in: 1 # TTL in seconds

  def cache_key
    "%s:%s" % [object.id, object.updated_at.to_i]
  end
end

scope "using redis as a store" do
  prepare { $redis.call("DEL", "1:1479693600") }

  prepare do
    @person = Person.new(1, "Jane Doe", Time.parse("2016-11-20 23:00:00"))
  end

  setup do
    CacheableSerializer.new(@person)
  end

  test "stores the serialized output in redis" do |serializer|
    result = serializer.to_json
    assert_equal result, $redis.call("GET", serializer.cache_key)
  end

  test "expires keys based on the expiration set in the options" do |serializer|
    result = serializer.to_json
    assert_equal result, $redis.call("GET", serializer.cache_key)

    sleep 1.1
    assert_equal nil, $redis.call("GET", serializer.cache_key)
  end
end
