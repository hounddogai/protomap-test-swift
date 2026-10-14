import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment schedules by code.
    protocol AssessmentScheduleStore {
        func find(_ code: String) -> AssessmentSchedule?
        func save(_ item: AssessmentSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentScheduleStore: AssessmentScheduleStore {
        var items: [String: AssessmentSchedule]
        var order: [String]

        init(items: [String: AssessmentSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentSchedule) {
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

        func list() -> [AssessmentSchedule] {
            var out: [AssessmentSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentScheduleStore() -> any AssessmentScheduleStore {
        return MemoryAssessmentScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentScheduleStore: AssessmentScheduleStore {
        var inner: MemoryAssessmentScheduleStore
        var cache: TTLCache<AssessmentSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentScheduleStore, cache: TTLCache<AssessmentSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentSchedule? {
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

        func save(_ item: AssessmentSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentSchedule] {
            return inner.list()
        }
    }

    static func newCachedAssessmentScheduleStore(_ inner: MemoryAssessmentScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentScheduleStore {
        return CachedAssessmentScheduleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment schedules. Empty fields match all.
    final class AssessmentScheduleQuery {
        var title: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentSchedule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentSchedule]) -> [AssessmentSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentSchedules(_ store: any AssessmentScheduleStore, query: AssessmentScheduleQuery) -> [AssessmentSchedule] {
        return query.apply(store.list())
    }
}
