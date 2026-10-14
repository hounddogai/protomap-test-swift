import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive statement schedules by code.
    protocol AdaptiveStatementScheduleStore {
        func find(_ code: String) -> AdaptiveStatementSchedule?
        func save(_ item: AdaptiveStatementSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveStatementSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveStatementScheduleStore: AdaptiveStatementScheduleStore {
        var items: [String: AdaptiveStatementSchedule]
        var order: [String]

        init(items: [String: AdaptiveStatementSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveStatementSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveStatementSchedule) {
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

        func list() -> [AdaptiveStatementSchedule] {
            var out: [AdaptiveStatementSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveStatementScheduleStore() -> any AdaptiveStatementScheduleStore {
        return MemoryAdaptiveStatementScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveStatementScheduleStore: AdaptiveStatementScheduleStore {
        var inner: MemoryAdaptiveStatementScheduleStore
        var cache: TTLCache<AdaptiveStatementSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveStatementScheduleStore, cache: TTLCache<AdaptiveStatementSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveStatementSchedule? {
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

        func save(_ item: AdaptiveStatementSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveStatementSchedule] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveStatementScheduleStore(_ inner: MemoryAdaptiveStatementScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveStatementScheduleStore {
        return CachedAdaptiveStatementScheduleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive statement schedules. Empty fields match all.
    final class AdaptiveStatementScheduleQuery {
        var label: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveStatementSchedule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveStatementSchedule]) -> [AdaptiveStatementSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveStatementSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveStatementSchedules(_ store: any AdaptiveStatementScheduleStore, query: AdaptiveStatementScheduleQuery) -> [AdaptiveStatementSchedule] {
        return query.apply(store.list())
    }
}
