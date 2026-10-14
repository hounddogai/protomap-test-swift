import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps capped assessment schedules by code.
    protocol CappedAssessmentScheduleStore {
        func find(_ code: String) -> CappedAssessmentSchedule?
        func save(_ item: CappedAssessmentSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [CappedAssessmentSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedAssessmentScheduleStore: CappedAssessmentScheduleStore {
        var items: [String: CappedAssessmentSchedule]
        var order: [String]

        init(items: [String: CappedAssessmentSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedAssessmentSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedAssessmentSchedule) {
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

        func list() -> [CappedAssessmentSchedule] {
            var out: [CappedAssessmentSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedAssessmentScheduleStore() -> any CappedAssessmentScheduleStore {
        return MemoryCappedAssessmentScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedAssessmentScheduleStore: CappedAssessmentScheduleStore {
        var inner: MemoryCappedAssessmentScheduleStore
        var cache: TTLCache<CappedAssessmentSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedAssessmentScheduleStore, cache: TTLCache<CappedAssessmentSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedAssessmentSchedule? {
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

        func save(_ item: CappedAssessmentSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedAssessmentSchedule] {
            return inner.list()
        }
    }

    static func newCachedCappedAssessmentScheduleStore(_ inner: MemoryCappedAssessmentScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedAssessmentScheduleStore {
        return CachedCappedAssessmentScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped assessment schedules. Empty fields match all.
    final class CappedAssessmentScheduleQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedAssessmentSchedule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedAssessmentSchedule]) -> [CappedAssessmentSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedAssessmentSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedAssessmentSchedules(_ store: any CappedAssessmentScheduleStore, query: CappedAssessmentScheduleQuery) -> [CappedAssessmentSchedule] {
        return query.apply(store.list())
    }
}
