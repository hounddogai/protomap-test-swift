import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive specimen schedules by code.
    protocol AdaptiveSpecimenScheduleStore {
        func find(_ code: String) -> AdaptiveSpecimenSchedule?
        func save(_ item: AdaptiveSpecimenSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveSpecimenSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveSpecimenScheduleStore: AdaptiveSpecimenScheduleStore {
        var items: [String: AdaptiveSpecimenSchedule]
        var order: [String]

        init(items: [String: AdaptiveSpecimenSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveSpecimenSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveSpecimenSchedule) {
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

        func list() -> [AdaptiveSpecimenSchedule] {
            var out: [AdaptiveSpecimenSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveSpecimenScheduleStore() -> any AdaptiveSpecimenScheduleStore {
        return MemoryAdaptiveSpecimenScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveSpecimenScheduleStore: AdaptiveSpecimenScheduleStore {
        var inner: MemoryAdaptiveSpecimenScheduleStore
        var cache: TTLCache<AdaptiveSpecimenSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveSpecimenScheduleStore, cache: TTLCache<AdaptiveSpecimenSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveSpecimenSchedule? {
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

        func save(_ item: AdaptiveSpecimenSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveSpecimenSchedule] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveSpecimenScheduleStore(_ inner: MemoryAdaptiveSpecimenScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveSpecimenScheduleStore {
        return CachedAdaptiveSpecimenScheduleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive specimen schedules. Empty fields match all.
    final class AdaptiveSpecimenScheduleQuery {
        var category: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveSpecimenSchedule) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveSpecimenSchedule]) -> [AdaptiveSpecimenSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveSpecimenSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveSpecimenSchedules(_ store: any AdaptiveSpecimenScheduleStore, query: AdaptiveSpecimenScheduleQuery) -> [AdaptiveSpecimenSchedule] {
        return query.apply(store.list())
    }
}
