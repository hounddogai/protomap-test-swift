import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility schedules by code.
    protocol EligibilityScheduleStore {
        func find(_ code: String) -> EligibilitySchedule?
        func save(_ item: EligibilitySchedule)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilitySchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityScheduleStore: EligibilityScheduleStore {
        var items: [String: EligibilitySchedule]
        var order: [String]

        init(items: [String: EligibilitySchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilitySchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilitySchedule) {
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

        func list() -> [EligibilitySchedule] {
            var out: [EligibilitySchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityScheduleStore() -> any EligibilityScheduleStore {
        return MemoryEligibilityScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityScheduleStore: EligibilityScheduleStore {
        var inner: MemoryEligibilityScheduleStore
        var cache: TTLCache<EligibilitySchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityScheduleStore, cache: TTLCache<EligibilitySchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilitySchedule? {
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

        func save(_ item: EligibilitySchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilitySchedule] {
            return inner.list()
        }
    }

    static func newCachedEligibilityScheduleStore(_ inner: MemoryEligibilityScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityScheduleStore {
        return CachedEligibilityScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility schedules. Empty fields match all.
    final class EligibilityScheduleQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilitySchedule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilitySchedule]) -> [EligibilitySchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilitySchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilitySchedules(_ store: any EligibilityScheduleStore, query: EligibilityScheduleQuery) -> [EligibilitySchedule] {
        return query.apply(store.list())
    }
}
