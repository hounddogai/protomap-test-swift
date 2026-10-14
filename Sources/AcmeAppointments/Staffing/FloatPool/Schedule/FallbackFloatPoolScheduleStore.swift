import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback float pool schedules by code.
    protocol FallbackFloatPoolScheduleStore {
        func find(_ code: String) -> FallbackFloatPoolSchedule?
        func save(_ item: FallbackFloatPoolSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackFloatPoolSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackFloatPoolScheduleStore: FallbackFloatPoolScheduleStore {
        var items: [String: FallbackFloatPoolSchedule]
        var order: [String]

        init(items: [String: FallbackFloatPoolSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackFloatPoolSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackFloatPoolSchedule) {
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

        func list() -> [FallbackFloatPoolSchedule] {
            var out: [FallbackFloatPoolSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackFloatPoolScheduleStore() -> any FallbackFloatPoolScheduleStore {
        return MemoryFallbackFloatPoolScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackFloatPoolScheduleStore: FallbackFloatPoolScheduleStore {
        var inner: MemoryFallbackFloatPoolScheduleStore
        var cache: TTLCache<FallbackFloatPoolSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackFloatPoolScheduleStore, cache: TTLCache<FallbackFloatPoolSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackFloatPoolSchedule? {
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

        func save(_ item: FallbackFloatPoolSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackFloatPoolSchedule] {
            return inner.list()
        }
    }

    static func newCachedFallbackFloatPoolScheduleStore(_ inner: MemoryFallbackFloatPoolScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackFloatPoolScheduleStore {
        return CachedFallbackFloatPoolScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback float pool schedules. Empty fields match all.
    final class FallbackFloatPoolScheduleQuery {
        var country: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackFloatPoolSchedule) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackFloatPoolSchedule]) -> [FallbackFloatPoolSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackFloatPoolSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackFloatPoolSchedules(_ store: any FallbackFloatPoolScheduleStore, query: FallbackFloatPoolScheduleQuery) -> [FallbackFloatPoolSchedule] {
        return query.apply(store.list())
    }
}
