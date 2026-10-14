import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps batched credential schedules by code.
    protocol BatchedCredentialScheduleStore {
        func find(_ code: String) -> BatchedCredentialSchedule?
        func save(_ item: BatchedCredentialSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCredentialSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCredentialScheduleStore: BatchedCredentialScheduleStore {
        var items: [String: BatchedCredentialSchedule]
        var order: [String]

        init(items: [String: BatchedCredentialSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCredentialSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCredentialSchedule) {
            if !(items[item.code] != nil) {
                order.append(item.code)
            }
            items[item.code] = item
        }

        func remove(_ code: String) -> Bool {
            if !(items[code] != nil) {
                return false
            }
            items.removeValue(forKey: code)
            var kept: [String] = []
            for existing in order {
                if existing != code {
                    kept.append(existing)
                }
            }
            order = kept
            return true
        }

        func list() -> [BatchedCredentialSchedule] {
            var out: [BatchedCredentialSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCredentialScheduleStore() -> any BatchedCredentialScheduleStore {
        return MemoryBatchedCredentialScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCredentialScheduleStore: BatchedCredentialScheduleStore {
        var inner: MemoryBatchedCredentialScheduleStore
        var cache: TTLCache<BatchedCredentialSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCredentialScheduleStore, cache: TTLCache<BatchedCredentialSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCredentialSchedule? {
            guard let hit = cache.getValue(code) else {
                misses += 1
                guard let found = inner.find(code) else {
                    return nil
                }
                cache.put(code, value: found)
                return found
            }
            hits += 1
            return hit
        }

        func save(_ item: BatchedCredentialSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCredentialSchedule] {
            return inner.list()
        }
    }

    static func newCachedBatchedCredentialScheduleStore(_ inner: MemoryBatchedCredentialScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCredentialScheduleStore {
        return CachedBatchedCredentialScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched credential schedules. Empty fields match all.
    final class BatchedCredentialScheduleQuery {
        var unit: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRefills: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCredentialSchedule) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedCredentialSchedule]) -> [BatchedCredentialSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCredentialSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCredentialSchedules(_ store: any BatchedCredentialScheduleStore, query: BatchedCredentialScheduleQuery) -> [BatchedCredentialSchedule] {
        return query.apply(store.list())
    }
}
