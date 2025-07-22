# Simple Cycle-Based Idempotency System

## Overview

This document describes the simplified, cycle-based idempotency system for game loop jobs. The system removes all time-based complexity and hardcoded durations in favor of a straightforward progress tracking approach.

## Key Principles

1. **Cycle-Based Tracking**: Each game loop cycle has a unique ID, and we track which villages/buildings have been processed in that cycle.
2. **No Time Durations**: Removed all time-based idempotency checks and hardcoded durations.
3. **Simple Progress Recording**: Use `GameLoopProgress` model to track what has been processed in each cycle.
4. **Configurable Values**: Any remaining time-based configuration uses configurable values instead of hardcoded durations.

## How It Works

### 1. Game Loop Level (`PlayLoopJob` → `PlayLoopService`)
- Each game loop cycle gets a unique `loop_cycle_id` (from `GameLoopState.id`)
- `PlayLoopService` tracks which villages have been queued for processing in this cycle
- On retry, only villages that haven't been queued yet are processed
- Uses `GameLoopProgress.mark_village_queued!()` to record progress

### 2. Village Level (`VillageLoopJob` → `VillageLoopService`)
- Tracks which buildings have been processed for each village in the current cycle
- On retry, only buildings that haven't been processed yet are queued
- Uses `GameLoopProgress.mark_building_processed!()` to record progress

### 3. Resource Production Level (`ProduceResourcesFromBuildingJob` → `ProduceResourcesFromBuildingService`)
- Checks if resources have already been produced for a building in the current cycle
- Uses `ResourceProduction.produced_in_cycle?()` for idempotency
- Completely cycle-based - no time windows or hardcoded durations

## Models

### GameLoopProgress
```ruby
# Tracks processing progress within each game loop cycle
- loop_cycle_id: String (the cycle identifier)
- progress_type: String ('village_queued', 'building_processed')
- village: Reference (optional)
- building: Reference (optional)  
- completed_at: DateTime
```

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

1. **Simple**: No complex time window calculations or failure recovery
2. **Robust**: Handles retries and failures gracefully using cycle-based tracking
3. **Idempotent**: Each operation in a cycle happens exactly once
4. **Configurable**: No hardcoded durations, everything is configurable
5. **Debuggable**: Clear progress tracking for each cycle

## Migration from Time-Based System

- Removed all hardcoded time durations (e.g., `25.seconds`, `30.minutes`)
- Deprecated `ResourceProduction.recently_produced?()` method
- Added cycle-based `ResourceProduction.produced_in_cycle?()` method
- Created `GameLoopProgress` model for simple progress tracking
- Made all remaining time-based config values configurable

## Testing

The system can be tested end-to-end:

```ruby
# Test complete cycle
cycle_id = "test-cycle-#{Time.current.to_i}"
PlayLoopService.call(loop_cycle_id: cycle_id)
VillageLoopService.call(village_id, loop_cycle_id: cycle_id)
ProduceResourcesFromBuildingService.call(building_id, village, 1, loop_cycle_id: cycle_id)

# Test idempotency - second call should skip
result = ProduceResourcesFromBuildingService.call(building_id, village, 1, loop_cycle_id: cycle_id)
# result.data[:skipped] should be true
```

## Cleanup

The system includes configurable cleanup methods:
- `GameLoopProgress.cleanup_old_progress!()` - removes old cycle records
- `ResourceProduction.cleanup_old_productions!()` - removes old production records
- `GameLoopState.cleanup_old_loops!()` - removes old loop state records

All cleanup durations are configurable and have sensible defaults.
