import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped network schedules by code.
    protocol CappedNetworkScheduleStore {
        func find(_ code: String) -> CappedNetworkSchedule?
        func save(_ item: CappedNetworkSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [CappedNetworkSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedNetworkScheduleStore: CappedNetworkScheduleStore {
        var items: [String: CappedNetworkSchedule]
        var order: [String]

        init(items: [String: CappedNetworkSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedNetworkSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedNetworkSchedule) {
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

        func list() -> [CappedNetworkSchedule] {
            var out: [CappedNetworkSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedNetworkScheduleStore() -> any CappedNetworkScheduleStore {
        return MemoryCappedNetworkScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedNetworkScheduleStore: CappedNetworkScheduleStore {
        var inner: MemoryCappedNetworkScheduleStore
        var cache: TTLCache<CappedNetworkSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedNetworkScheduleStore, cache: TTLCache<CappedNetworkSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedNetworkSchedule? {
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

        func save(_ item: CappedNetworkSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedNetworkSchedule] {
            return inner.list()
        }
    }

    static func newCachedCappedNetworkScheduleStore(_ inner: MemoryCappedNetworkScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedNetworkScheduleStore {
        return CachedCappedNetworkScheduleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped network schedules. Empty fields match all.
    final class CappedNetworkScheduleQuery {
        var country: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minScore: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedNetworkSchedule) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedNetworkSchedule]) -> [CappedNetworkSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedNetworkSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedNetworkSchedules(_ store: any CappedNetworkScheduleStore, query: CappedNetworkScheduleQuery) -> [CappedNetworkSchedule] {
        return query.apply(store.list())
    }
}
