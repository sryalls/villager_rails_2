# Simple Cycle-Based Idempotency System

## Overview

This document describes the simplified, cycle-based idempotency system for game loop jobs. The system removes all time-based complexity and hardcoded durations in favor of a straightforward progress tracking approach using a single consolidated model.

## Key Principles

1. **Cycle-Based Tracking**: Each game loop cycle has a unique ID, and we track which villages/buildings have been processed in that cycle.
2. **No Time Durations**: Removed all time-based idempotency checks and hardcoded durations.
3. **Consolidated State Management**: Use `GameLoopState` model to manage both loop lifecycle and progress tracking.
4. **Configurable Values**: Any remaining time-based configuration uses configurable values instead of hardcoded durations.

## How It Works

### 1. Game Loop Level (`PlayLoopJob` → `PlayLoopService`)
- Each game loop cycle gets a unique `GameLoopState` instance
- `PlayLoopService` tracks which villages have been queued for processing in this loop
- On retry, only villages that haven't been queued yet are processed
- Uses `loop_state.mark_village_queued!(village)` to record progress

### 2. Village Level (`VillageLoopJob` → `VillageLoopService`)
- Tracks which buildings have been processed for each village in the current loop
- On retry, only buildings that haven't been processed yet are queued
- Uses `loop_state.mark_building_processed!(village, building)` to record progress

### 3. Resource Production Level (`ProduceResourcesFromBuildingJob` → `ProduceResourcesFromBuildingService`)
- Checks if resources have already been produced for a building in the current cycle
- Uses `ResourceProduction.produced_in_cycle?(cycle_id, building, village)` for idempotency
- Completely cycle-based - no time windows or hardcoded durations

## Models

### GameLoopState (Consolidated)
```ruby
# Manages both loop lifecycle and progress tracking
- loop_type: String ('play_loop', 'village_loop')
- identifier: String (optional identifier for village-specific loops)
- status: String ('running', 'completed', 'failed')
- started_at, completed_at: DateTime
- processed_villages: Array (JSON) - village IDs processed in this loop
- processed_buildings: Hash (JSON) - village_id => [building_ids] processed
```

**Key Methods:**
- `mark_village_queued!(village)` - Record village as queued
- `mark_building_processed!(village, building)` - Record building as processed
- `village_queued?(village)` - Check if village was queued
- `building_processed?(village, building)` - Check if building was processed
- `queued_villages` - Get villages queued in this loop
- `processed_buildings_for_village(village)` - Get buildings processed for village

### ResourceProduction
```ruby
# Records actual resource production events
- village, building, resource: References
- quantity_produced: Integer
- building_multiplier: Integer
- produced_at: DateTime
- loop_cycle_id: String (for cycle-based idempotency)
```

## Configuration

All time-based values are now configurable in `config/application.rb`:

```ruby
# Game loop configuration
config.game_loop_cleanup_keep_duration = 24.hours
config.resource_production_cleanup_keep_duration = 7.days
config.resource_production_window = 25.seconds # Legacy (deprecated)
```

## Benefits

1. **Simple**: No complex time window calculations or separate progress tracking model
2. **Robust**: Handles retries and failures gracefully using cycle-based tracking
3. **Idempotent**: Each operation in a cycle happens exactly once
4. **Configurable**: No hardcoded durations, everything is configurable
5. **Consolidated**: Single model manages both loop state and progress tracking
6. **Debuggable**: Clear progress tracking for each cycle with easy introspection

## Migration from Time-Based System

- Removed all hardcoded time durations (e.g., `25.seconds`, `30.minutes`)
- Deprecated `ResourceProduction.recently_produced?()` method
- Added cycle-based `ResourceProduction.produced_in_cycle?()` method
- **Consolidated `GameLoopProgress` into `GameLoopState`** - single model for state and progress
- Made all remaining time-based config values configurable

## Testing

The system can be tested end-to-end:

```ruby
# Create a loop state
loop_state = GameLoopState.start_loop!("play_loop", nil, "test-job")

# Test complete cycle
PlayLoopService.call(loop_state: loop_state)
VillageLoopService.call(village_id, loop_state: loop_state)
ProduceResourcesFromBuildingService.call(building_id, village, 1, loop_cycle_id: loop_state.id)

# Test idempotency - second call should skip
result = ProduceResourcesFromBuildingService.call(building_id, village, 1, loop_cycle_id: loop_state.id)
# result.data[:skipped] should be true

# Check progress
loop_state.village_queued?(village)     # => true
loop_state.building_processed?(village, building)  # => true
```

## Cleanup

The system includes configurable cleanup methods:
- `ResourceProduction.cleanup_old_productions!()` - removes old production records
- `GameLoopState.cleanup_old_loops!()` - removes old loop state records

All cleanup durations are configurable and have sensible defaults.
