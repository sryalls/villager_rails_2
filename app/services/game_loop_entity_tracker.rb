class GameLoopEntityTracker
  # Redis TTL for entity tracking (default 2 hours)
  DEFAULT_TTL = 2.hours

  def initialize(loop_id)
    @loop_id = loop_id
  end

  # Entity tracking methods

  def mark_entity_processed!(entity_type, entity_id, parent_type: nil, parent_id: nil)
    key = entity_key(entity_type, entity_id, parent_type, parent_id)
    Rails.cache.write(key, true, expires_in: DEFAULT_TTL)
  end

  def entity_processed?(entity_type, entity_id, parent_type: nil, parent_id: nil)
    key = entity_key(entity_type, entity_id, parent_type, parent_id)
    Rails.cache.read(key) || false
  end

  def get_processed_entities(entity_type, parent_type: nil, parent_id: nil)
    pattern = entity_pattern(entity_type, parent_type, parent_id)
    keys = find_keys_by_pattern(pattern)
    extract_entity_ids_from_keys(keys, entity_type)
  end

  def mark_entity_batch_processed!(entity_type, entity_ids, parent_type: nil, parent_id: nil)
    # Use write_multi for efficiency when marking multiple entities
    Rails.cache.write_multi(
      entity_ids.each_with_object({}) do |entity_id, hash|
        key = entity_key(entity_type, entity_id, parent_type, parent_id)
        hash[key] = true
      end,
      expires_in: DEFAULT_TTL
    )
  end

  def cleanup_entities_for_loop!
    pattern = "game_loop:#{@loop_id}:*"
    keys = find_keys_by_pattern(pattern)
    Rails.cache.delete_multi(keys) if keys.any?
  end

  # Specialized convenience methods for game entities

  def mark_village_queued!(village_id)
    mark_entity_processed!("village", village_id)
  end

  def village_queued?(village_id)
    entity_processed?("village", village_id)
  end

  def get_queued_villages
    get_processed_entities("village")
  end

  def mark_building_processed!(building_id, village_id)
    mark_entity_processed!("building", building_id, parent_type: "village", parent_id: village_id)
  end

  def building_processed?(building_id, village_id)
    entity_processed?("building", building_id, parent_type: "village", parent_id: village_id)
  end

  def get_processed_buildings_for_village(village_id)
    get_processed_entities("building", parent_type: "village", parent_id: village_id)
  end

  def mark_resource_produced!(resource_id, building_id, village_id)
    mark_entity_processed!("resource", resource_id, parent_type: "building", parent_id: "#{village_id}:#{building_id}")
  end

  def resource_produced?(resource_id, building_id, village_id)
    entity_processed?("resource", resource_id, parent_type: "building", parent_id: "#{village_id}:#{building_id}")
  end

  # Future extensibility examples:
  # def mark_quest_completed!(quest_id, village_id)
  #   mark_entity_processed!("quest", quest_id, parent_type: "village", parent_id: village_id)
  # end
  #
  # def mark_research_processed!(research_id)
  #   mark_entity_processed!("research", research_id)
  # end

  private

  def entity_key(entity_type, entity_id, parent_type, parent_id)
    if parent_type && parent_id
      "game_loop:#{@loop_id}:#{parent_type}:#{parent_id}:#{entity_type}:#{entity_id}"
    else
      "game_loop:#{@loop_id}:#{entity_type}:#{entity_id}"
    end
  end

  def entity_pattern(entity_type, parent_type, parent_id)
    if parent_type && parent_id
      "game_loop:#{@loop_id}:#{parent_type}:#{parent_id}:#{entity_type}:*"
    else
      "game_loop:#{@loop_id}:#{entity_type}:*"
    end
  end

  def find_keys_by_pattern(pattern)
    # Note: In production, consider using SCAN instead of KEYS for large datasets
    # This is a simplified implementation
    if Rails.cache.respond_to?(:redis)
      Rails.cache.redis.keys(pattern)
    else
      # Fallback for non-Redis cache stores (testing, etc.)
      # This is less efficient but provides compatibility
      []
    end
  end

  def extract_entity_ids_from_keys(keys, entity_type)
    keys.filter_map do |key|
      # Extract entity ID from the key structure
      parts = key.split(":")
      entity_index = parts.rindex(entity_type)
      next unless entity_index && entity_index < parts.length - 1

      entity_id = parts[entity_index + 1]
      entity_id.to_i if entity_id.match?(/^\d+$/)
    end
  end
end
