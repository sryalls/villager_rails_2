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
The system follows a clean separation of concerns:
- **Jobs**: Handle job orchestration and delegation only
- **Services**: Handle all business logic and loop state management
- **Models**: Handle data persistence and state tracking

### 1. Game Loop Level (`PlayLoopJob` → `PlayLoopService`)
- **Job**: Simply delegates to `PlayLoopService.call(job_id: job_id)`
- **Service**: Manages the entire play loop lifecycle:
  - Checks if loop can start
  - Creates and manages `GameLoopState`
  - Tracks which villages have been queued for processing
  - Handles completion and failure scenarios
  - On retry, only villages that haven't been queued yet are processed

### 2. Village Level (`VillageLoopJob` → `VillageLoopService`)
- **Job**: Simply delegates to `VillageLoopService.call(village_id, loop_cycle_id: cycle_id, job_id: job_id)`
- **Service**: Manages the village loop lifecycle:
  - Checks if village loop can start
  - Creates village-specific `GameLoopState`
  - Gets main play loop state for progress tracking
  - Tracks which buildings have been processed for the village
  - Handles completion and failure scenarios
  - On retry, only buildings that haven't been processed yet are queued

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
6. **Clean Architecture**: Jobs focus on orchestration, services handle all business logic
7. **Testable**: Services can be tested independently without job infrastructure
8. **Debuggable**: Clear progress tracking for each cycle with easy introspection

## Migration from Time-Based System

- Removed all hardcoded time durations (e.g., `25.seconds`, `30.minutes`)
- Deprecated `ResourceProduction.recently_produced?()` method
- Added cycle-based `ResourceProduction.produced_in_cycle?()` method
- **Consolidated `GameLoopProgress` into `GameLoopState`** - single model for state and progress
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
