import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study assignments by code.
    protocol StudyAssignmentStore {
        func find(_ code: String) -> StudyAssignment?
        func save(_ item: StudyAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [StudyAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyAssignmentStore: StudyAssignmentStore {
        var items: [String: StudyAssignment]
        var order: [String]

        init(items: [String: StudyAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyAssignment) {
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

        func list() -> [StudyAssignment] {
            var out: [StudyAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyAssignmentStore() -> any StudyAssignmentStore {
        return MemoryStudyAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyAssignmentStore: StudyAssignmentStore {
        var inner: MemoryStudyAssignmentStore
        var cache: TTLCache<StudyAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyAssignmentStore, cache: TTLCache<StudyAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyAssignment? {
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

        func save(_ item: StudyAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyAssignment] {
            return inner.list()
        }
    }

    static func newCachedStudyAssignmentStore(_ inner: MemoryStudyAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyAssignmentStore {
        return CachedStudyAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study assignments. Empty fields match all.
    final class StudyAssignmentQuery {
        var source: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyAssignment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [StudyAssignment]) -> [StudyAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyAssignments(_ store: any StudyAssignmentStore, query: StudyAssignmentQuery) -> [StudyAssignment] {
        return query.apply(store.list())
    }
}
