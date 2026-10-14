import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps legacy task schedules by code.
    protocol LegacyTaskScheduleStore {
        func find(_ code: String) -> LegacyTaskSchedule?
        func save(_ item: LegacyTaskSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyTaskSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyTaskScheduleStore: LegacyTaskScheduleStore {
        var items: [String: LegacyTaskSchedule]
        var order: [String]

        init(items: [String: LegacyTaskSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyTaskSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyTaskSchedule) {
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

        func list() -> [LegacyTaskSchedule] {
            var out: [LegacyTaskSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyTaskScheduleStore() -> any LegacyTaskScheduleStore {
        return MemoryLegacyTaskScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyTaskScheduleStore: LegacyTaskScheduleStore {
        var inner: MemoryLegacyTaskScheduleStore
        var cache: TTLCache<LegacyTaskSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyTaskScheduleStore, cache: TTLCache<LegacyTaskSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyTaskSchedule? {
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

        func save(_ item: LegacyTaskSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyTaskSchedule] {
            return inner.list()
        }
    }

    static func newCachedLegacyTaskScheduleStore(_ inner: MemoryLegacyTaskScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyTaskScheduleStore {
        return CachedLegacyTaskScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy task schedules. Empty fields match all.
    final class LegacyTaskScheduleQuery {
        var source: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyTaskSchedule) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyTaskSchedule]) -> [LegacyTaskSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyTaskSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyTaskSchedules(_ store: any LegacyTaskScheduleStore, query: LegacyTaskScheduleQuery) -> [LegacyTaskSchedule] {
        return query.apply(store.list())
    }
}
