import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure assignments by code.
    protocol ClosureAssignmentStore {
        func find(_ code: String) -> ClosureAssignment?
        func save(_ item: ClosureAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureAssignmentStore: ClosureAssignmentStore {
        var items: [String: ClosureAssignment]
        var order: [String]

        init(items: [String: ClosureAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureAssignment) {
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

        func list() -> [ClosureAssignment] {
            var out: [ClosureAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureAssignmentStore() -> any ClosureAssignmentStore {
        return MemoryClosureAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureAssignmentStore: ClosureAssignmentStore {
        var inner: MemoryClosureAssignmentStore
        var cache: TTLCache<ClosureAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureAssignmentStore, cache: TTLCache<ClosureAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureAssignment? {
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

        func save(_ item: ClosureAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureAssignment] {
            return inner.list()
        }
    }

    static func newCachedClosureAssignmentStore(_ inner: MemoryClosureAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureAssignmentStore {
        return CachedClosureAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure assignments. Empty fields match all.
    final class ClosureAssignmentQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureAssignment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ClosureAssignment]) -> [ClosureAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureAssignments(_ store: any ClosureAssignmentStore, query: ClosureAssignmentQuery) -> [ClosureAssignment] {
        return query.apply(store.list())
    }
}
