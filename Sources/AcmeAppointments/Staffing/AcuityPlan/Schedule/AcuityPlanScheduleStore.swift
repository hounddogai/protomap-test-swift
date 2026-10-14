import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan schedules by code.
    protocol AcuityPlanScheduleStore {
        func find(_ code: String) -> AcuityPlanSchedule?
        func save(_ item: AcuityPlanSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanScheduleStore: AcuityPlanScheduleStore {
        var items: [String: AcuityPlanSchedule]
        var order: [String]

        init(items: [String: AcuityPlanSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanSchedule) {
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

        func list() -> [AcuityPlanSchedule] {
            var out: [AcuityPlanSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanScheduleStore() -> any AcuityPlanScheduleStore {
        return MemoryAcuityPlanScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanScheduleStore: AcuityPlanScheduleStore {
        var inner: MemoryAcuityPlanScheduleStore
        var cache: TTLCache<AcuityPlanSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanScheduleStore, cache: TTLCache<AcuityPlanSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanSchedule? {
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

        func save(_ item: AcuityPlanSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanSchedule] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanScheduleStore(_ inner: MemoryAcuityPlanScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanScheduleStore {
        return CachedAcuityPlanScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan schedules. Empty fields match all.
    final class AcuityPlanScheduleQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanSchedule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanSchedule]) -> [AcuityPlanSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanSchedules(_ store: any AcuityPlanScheduleStore, query: AcuityPlanScheduleQuery) -> [AcuityPlanSchedule] {
        return query.apply(store.list())
    }
}
