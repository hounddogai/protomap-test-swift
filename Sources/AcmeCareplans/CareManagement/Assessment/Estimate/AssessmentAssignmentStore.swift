import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment assignments by code.
    protocol AssessmentAssignmentStore {
        func find(_ code: String) -> AssessmentAssignment?
        func save(_ item: AssessmentAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentAssignmentStore: AssessmentAssignmentStore {
        var items: [String: AssessmentAssignment]
        var order: [String]

        init(items: [String: AssessmentAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentAssignment) {
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

        func list() -> [AssessmentAssignment] {
            var out: [AssessmentAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentAssignmentStore() -> any AssessmentAssignmentStore {
        return MemoryAssessmentAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentAssignmentStore: AssessmentAssignmentStore {
        var inner: MemoryAssessmentAssignmentStore
        var cache: TTLCache<AssessmentAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentAssignmentStore, cache: TTLCache<AssessmentAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentAssignment? {
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

        func save(_ item: AssessmentAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentAssignment] {
            return inner.list()
        }
    }

    static func newCachedAssessmentAssignmentStore(_ inner: MemoryAssessmentAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentAssignmentStore {
        return CachedAssessmentAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment assignments. Empty fields match all.
    final class AssessmentAssignmentQuery {
        var title: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minWeight: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentAssignment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [AssessmentAssignment]) -> [AssessmentAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentAssignments(_ store: any AssessmentAssignmentStore, query: AssessmentAssignmentQuery) -> [AssessmentAssignment] {
        return query.apply(store.list())
    }
}
