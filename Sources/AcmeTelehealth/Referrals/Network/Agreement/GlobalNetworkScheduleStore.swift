import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global network schedules by code.
    protocol GlobalNetworkScheduleStore {
        func find(_ code: String) -> GlobalNetworkSchedule?
        func save(_ item: GlobalNetworkSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalNetworkSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalNetworkScheduleStore: GlobalNetworkScheduleStore {
        var items: [String: GlobalNetworkSchedule]
        var order: [String]

        init(items: [String: GlobalNetworkSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalNetworkSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalNetworkSchedule) {
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

        func list() -> [GlobalNetworkSchedule] {
            var out: [GlobalNetworkSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalNetworkScheduleStore() -> any GlobalNetworkScheduleStore {
        return MemoryGlobalNetworkScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalNetworkScheduleStore: GlobalNetworkScheduleStore {
        var inner: MemoryGlobalNetworkScheduleStore
        var cache: TTLCache<GlobalNetworkSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalNetworkScheduleStore, cache: TTLCache<GlobalNetworkSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalNetworkSchedule? {
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

        func save(_ item: GlobalNetworkSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalNetworkSchedule] {
            return inner.list()
        }
    }

    static func newCachedGlobalNetworkScheduleStore(_ inner: MemoryGlobalNetworkScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalNetworkScheduleStore {
        return CachedGlobalNetworkScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global network schedules. Empty fields match all.
    final class GlobalNetworkScheduleQuery {
        var region: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalNetworkSchedule) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalNetworkSchedule]) -> [GlobalNetworkSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalNetworkSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalNetworkSchedules(_ store: any GlobalNetworkScheduleStore, query: GlobalNetworkScheduleQuery) -> [GlobalNetworkSchedule] {
        return query.apply(store.list())
    }
}
