require "granola/cache"

# Store that keeps track of how many times it rendered from cache or actually
# called the renderer.
class CounterStore < Granola::Cache::MemoryStore
  def fetch(key)
    self.from_cache += 1
    super(key) do
      self.rendered += 1
      self.from_cache -= 1
      yield
    end
  end

  attr_writer :rendered, :from_cache

  def rendered
    @rendered ||= 0
  end

  def from_cache
    @from_cache ||= 0
  end
end

Person = Struct.new(:id, :name, :updated_at)

class BaseSerializer < Granola::Serializer
  def data
    { "id" => object.id, "name" => object.name }
  end
end

# Clear the cache between tests
prepare { Granola::Cache.store = Granola::Cache::MemoryStore.new }
