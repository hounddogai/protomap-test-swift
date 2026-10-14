import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default risk score schedules by code.
    protocol DefaultRiskScoreScheduleStore {
        func find(_ code: String) -> DefaultRiskScoreSchedule?
        func save(_ item: DefaultRiskScoreSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRiskScoreSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRiskScoreScheduleStore: DefaultRiskScoreScheduleStore {
        var items: [String: DefaultRiskScoreSchedule]
        var order: [String]

        init(items: [String: DefaultRiskScoreSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRiskScoreSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRiskScoreSchedule) {
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

        func list() -> [DefaultRiskScoreSchedule] {
            var out: [DefaultRiskScoreSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRiskScoreScheduleStore() -> any DefaultRiskScoreScheduleStore {
        return MemoryDefaultRiskScoreScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRiskScoreScheduleStore: DefaultRiskScoreScheduleStore {
        var inner: MemoryDefaultRiskScoreScheduleStore
        var cache: TTLCache<DefaultRiskScoreSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRiskScoreScheduleStore, cache: TTLCache<DefaultRiskScoreSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRiskScoreSchedule? {
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

        func save(_ item: DefaultRiskScoreSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRiskScoreSchedule] {
            return inner.list()
        }
    }

    static func newCachedDefaultRiskScoreScheduleStore(_ inner: MemoryDefaultRiskScoreScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRiskScoreScheduleStore {
        return CachedDefaultRiskScoreScheduleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default risk score schedules. Empty fields match all.
    final class DefaultRiskScoreScheduleQuery {
        var name: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRiskScoreSchedule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultRiskScoreSchedule]) -> [DefaultRiskScoreSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRiskScoreSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRiskScoreSchedules(_ store: any DefaultRiskScoreScheduleStore, query: DefaultRiskScoreScheduleQuery) -> [DefaultRiskScoreSchedule] {
        return query.apply(store.list())
    }
}
