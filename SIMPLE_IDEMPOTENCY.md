# Simple Cycle-Based Idempotency System

## Overview

This document describes the simplified, cycle-based idempotency system for game loop jobs. The system removes all time-based complexity and hardcoded durations in favor of a straightforward progress tracking approach using a single consolidated model.

## Key Principles

1. **Cycle-Based Tracking**: Each game loop cycle has a unique ID, and we track which villages/buildings have been processed in that cycle.
2. **No Time Durations**: Removed all time-based idempotency checks and hardcoded durations.
3. **Consolidated State Management**: Use `GameLoopState` model to manage both loop lifecycle and progress tracking.
4. **Configurable Values**: Any remaining time-based configuration uses configurable values instead of hardcoded durations.

## How It Works

### Architecture Overview
The system follows a clean separation of concerns with **external state management** for maximum robustness:
- **GameLoopManager**: Handles atomic state creation and job queuing - prevents race conditions
- **Jobs**: Accept pre-created state IDs, validate state, and delegate to services
- **Services**: Handle pure business logic with injected state dependencies
- **Models**: Handle data persistence and state tracking

### 1. Game Loop Level
**External State Management Flow:**
```ruby
# External orchestration - Creates state atomically before enqueueing
GameLoopManager.queue_play_loop!(job_id: "scheduler-123")
# └─ Checks if loop can start
# └─ Creates GameLoopState atomically
# └─ Enqueues PlayLoopJob with loop_state_id
# └─ Returns success/failure

# Job - Accepts pre-created state ID
PlayLoopJob.perform_later(loop_state_id: state.id)
# └─ Looks up existing GameLoopState by ID
# └─ Validates state is still running
# └─ Calls PlayLoopService.call(loop_state: state)

# Service - Pure business logic
PlayLoopService.new(loop_state: state).call
# └─ Processes villages using GameLoopManager for sub-jobs
# └─ Tracks progress on the state
# └─ Completes or fails the loop state
```

### 2. Village Level  
**External State Management Flow:**
```ruby
# From PlayLoopService - Uses GameLoopManager for sub-jobs
GameLoopManager.queue_village_loop!(village_id, loop_cycle_id: main_loop_id)
# └─ Checks if village loop can start
# └─ Creates village GameLoopState atomically
# └─ Enqueues VillageLoopJob with village_loop_state_id
# └─ Returns success/failure

# Job - Accepts pre-created state ID
VillageLoopJob.perform_later(village_id, loop_cycle_id: main_loop_id, village_loop_state_id: village_state.id)
# └─ Looks up existing village GameLoopState by ID
# └─ Validates state is still running
# └─ Gets main loop state for progress tracking
# └─ Calls VillageLoopService.call(village_id, main_loop_state: main, village_loop_state: village)

# Service - Pure business logic
VillageLoopService.new(village_id, main_loop_state: main, village_loop_state: village).call
# └─ Processes buildings and tracks progress
# └─ Completes or fails the village loop state
```

### 3. Resource Production Level
- Same as before: Uses cycle-based `ResourceProduction.produced_in_cycle?()` for idempotency

## Data Storage

### Hierarchical Entity Tracking System
The system now uses a hierarchical, Redis-based architecture that scales much better as the game expands:

#### GameLoopState (Lifecycle Management)
Focused solely on loop lifecycle management - no entity tracking data stored here:

```ruby
# Redis-backed lifecycle management with automatic expiration
- id: String (UUID)
- loop_type: String ('play_loop', 'village_loop')
- identifier: String (optional identifier for village-specific loops)
- status: String ('running', 'completed', 'failed')
- started_at, completed_at: DateTime
- sidekiq_job_id: String (for debugging)
- error_message: String (for failed states)
```

**Key Methods:**
- `GameLoopState.can_start_loop?(type, identifier)` - Check if loop can start
- `GameLoopState.start_loop!(type, identifier, job_id)` - Atomically create running state
- Uses Redis `SET ... NX` for atomic lock acquisition
- Delegates entity tracking to `GameLoopEntityTracker`

#### GameLoopEntityTracker (Hierarchical Entity Management)
Uses many small Redis keys for scalable entity tracking:

**Redis Key Structure:**
```
game_loop:{loop_id}:{entity_type}:{entity_id}                    # Top-level entities
game_loop:{loop_id}:{parent_type}:{parent_id}:{entity_type}:{entity_id}  # Nested entities
```

**Examples:**
```
game_loop:abc123:village:101                           # Village 101 queued
game_loop:abc123:village:101:building:201              # Building 201 in Village 101 processed
game_loop:abc123:village:101:building:201:resource:301 # Resource 301 from Building 201 produced
```

**Key Methods:**
- `mark_entity_processed!(type, id, parent_type:, parent_id:)` - Generic entity tracking
- `mark_village_queued!(village_id)` - Specialized village tracking
- `mark_building_processed!(building_id, village_id)` - Hierarchical building tracking
- `mark_resource_produced!(resource_id, building_id, village_id)` - Deep hierarchy support
- `get_processed_entities(type, parent_type:, parent_id:)` - Retrieve entity lists
- `mark_entity_batch_processed!(type, ids, parent_type:, parent_id:)` - Batch operations

**Benefits:**
- **Scalable**: Each entity gets its own Redis key, no large JSON objects
- **Extensible**: Easy to add new entity types (quests, research, etc.)
- **Hierarchical**: Supports parent-child relationships (village → building → resource)
- **Performant**: Small keys = fast Redis operations
- **Batch Operations**: Efficient multi-entity processing
- **Auto-cleanup**: TTL handles expiration automatically

### ResourceProduction
```ruby
# Records actual resource production events (unchanged)
- village, building, resource: References
- quantity_produced: Integer
- building_multiplier: Integer
- produced_at: DateTime
- loop_cycle_id: String (for cycle-based idempotency)
```

## Configuration

## Configuration

Redis configuration is handled through the existing Rails cache configuration and Sidekiq Redis setup. The `GameLoopState` uses `Rails.cache` which should be backed by Redis in production.

**Redis Keys Used:**
- `game_loop_state:running:{loop_type}:{identifier}` - Running loop cache (atomic locks)
- `game_loop_state:{id}` - Individual state storage by ID

**TTL Settings:**
- Default TTL: 2 hours (configurable via `GameLoopState::DEFAULT_TTL`)
- Automatic cleanup: States expire automatically, no manual cleanup needed

Legacy database configuration (no longer used):
```ruby
# Game loop configuration - Redis replaces these
# config.game_loop_cleanup_keep_duration = 24.hours # Not needed with Redis TTL
config.resource_production_cleanup_keep_duration = 7.days # Still used for ResourceProduction
```

## Benefits

1. **Simple**: No complex time window calculations or separate progress tracking model
2. **Robust**: External state management prevents race conditions and handles job failures gracefully
3. **Atomic**: State creation happens atomically before job enqueueing, preventing orphaned jobs
4. **Idempotent**: Each operation in a cycle happens exactly once, with retry safety
5. **Testable**: Clean separation between orchestration (GameLoopManager), execution (Jobs), and logic (Services)
6. **Performant**: Redis-backed storage with small keys is much faster than database persistence
7. **Self-Cleaning**: Redis TTL automatically expires old states, no manual cleanup needed
8. **Scalable**: Hierarchical entity tracking scales to millions of entities without performance degradation
9. **Extensible**: Easy to add new entity types (quests, research, armies, etc.) without code changes
10. **Hierarchical**: Supports deep parent-child relationships (village → building → resource → upgrade)
11. **Batch Efficient**: Optimized multi-entity operations using Redis pipelines
12. **Memory Efficient**: Small individual keys instead of large JSON objects
13. **Fail-Safe**: If job enqueueing fails, the state is automatically marked as failed
14. **Appropriate Durability**: Game loop state doesn't need long-term persistence

## Future Extensibility Examples

The hierarchical system makes it trivial to add new game features:

```ruby
# Quest system
tracker.mark_entity_processed!("quest", quest_id, parent_type: "village", parent_id: village_id)

# Research system  
tracker.mark_entity_processed!("research", research_id)

# Army/combat system
tracker.mark_entity_processed!("battle", battle_id, parent_type: "village", parent_id: village_id)

# Trade system
tracker.mark_entity_processed!("trade", trade_id, parent_type: "village", parent_id: village_id)

# Resource upgrades
tracker.mark_entity_processed!("upgrade", upgrade_id, parent_type: "building", parent_id: "#{village_id}:#{building_id}")
```

## Migration from Monolithic System

- **Removed JSON arrays/objects** from GameLoopState (processed_villages, processed_buildings)
- **Introduced GameLoopEntityTracker** for hierarchical entity management
- **Maintained backward compatibility** via delegation methods in GameLoopState
- **Improved performance** by replacing large JSON operations with small Redis key operations
- Made all remaining time-based config values configurable

## Testing

The system can be tested at the service level without job infrastructure:

```ruby
# Test complete cycle at service level
result = PlayLoopService.call(job_id: "test-job")
village_id = Village.first.id
result2 = VillageLoopService.call(village_id, loop_cycle_id: result.data[:loop_state_id], job_id: "test-village")

# Test resource production
building_id = Building.first.id
village = Village.first
result3 = ProduceResourcesFromBuildingService.call(building_id, village, 1, loop_cycle_id: result.data[:loop_state_id])

# Test idempotency - second call should skip
result4 = ProduceResourcesFromBuildingService.call(building_id, village, 1, loop_cycle_id: result.data[:loop_state_id])
# result4.data[:skipped] should be true

# Check progress directly on the loop state
loop_state = GameLoopState.find(result.data[:loop_state_id])
loop_state.village_queued?(village)     # => true
loop_state.building_processed?(village, Building.first)  # => true
```

Jobs are simple and just delegate:
```ruby
# Job execution is just delegation
PlayLoopJob.perform_now("test-job-id")
VillageLoopJob.perform_now(village_id, loop_cycle_id: loop_state_id)
```

## Cleanup

The system includes configurable cleanup methods:
- `ResourceProduction.cleanup_old_productions!()` - removes old production records
- `GameLoopState.cleanup_old_loops!()` - removes old loop state records

All cleanup durations are configurable and have sensible defaults.
