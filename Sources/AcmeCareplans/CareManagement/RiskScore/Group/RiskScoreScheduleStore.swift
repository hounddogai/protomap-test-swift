import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score schedules by code.
    protocol RiskScoreScheduleStore {
        func find(_ code: String) -> RiskScoreSchedule?
        func save(_ item: RiskScoreSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreScheduleStore: RiskScoreScheduleStore {
        var items: [String: RiskScoreSchedule]
        var order: [String]

        init(items: [String: RiskScoreSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreSchedule) {
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

        func list() -> [RiskScoreSchedule] {
            var out: [RiskScoreSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreScheduleStore() -> any RiskScoreScheduleStore {
        return MemoryRiskScoreScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreScheduleStore: RiskScoreScheduleStore {
        var inner: MemoryRiskScoreScheduleStore
        var cache: TTLCache<RiskScoreSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreScheduleStore, cache: TTLCache<RiskScoreSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreSchedule? {
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

        func save(_ item: RiskScoreSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreSchedule] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreScheduleStore(_ inner: MemoryRiskScoreScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreScheduleStore {
        return CachedRiskScoreScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score schedules. Empty fields match all.
    final class RiskScoreScheduleQuery {
        var unit: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minLimit: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreSchedule) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreSchedule]) -> [RiskScoreSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreSchedules(_ store: any RiskScoreScheduleStore, query: RiskScoreScheduleQuery) -> [RiskScoreSchedule] {
        return query.apply(store.list())
    }
}
