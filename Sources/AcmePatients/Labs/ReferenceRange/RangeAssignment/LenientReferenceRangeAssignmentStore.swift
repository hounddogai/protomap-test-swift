import AcmePlatform
import Foundation

extension Labs {
    /// Keeps lenient reference range assignments by code.
    protocol LenientReferenceRangeAssignmentStore {
        func find(_ code: String) -> LenientReferenceRangeAssignment?
        func save(_ item: LenientReferenceRangeAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [LenientReferenceRangeAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientReferenceRangeAssignmentStore: LenientReferenceRangeAssignmentStore {
        var items: [String: LenientReferenceRangeAssignment]
        var order: [String]

        init(items: [String: LenientReferenceRangeAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientReferenceRangeAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientReferenceRangeAssignment) {
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

        func list() -> [LenientReferenceRangeAssignment] {
            var out: [LenientReferenceRangeAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientReferenceRangeAssignmentStore() -> any LenientReferenceRangeAssignmentStore {
        return MemoryLenientReferenceRangeAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientReferenceRangeAssignmentStore: LenientReferenceRangeAssignmentStore {
        var inner: MemoryLenientReferenceRangeAssignmentStore
        var cache: TTLCache<LenientReferenceRangeAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientReferenceRangeAssignmentStore, cache: TTLCache<LenientReferenceRangeAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientReferenceRangeAssignment? {
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

        func save(_ item: LenientReferenceRangeAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientReferenceRangeAssignment] {
            return inner.list()
        }
    }

    static func newCachedLenientReferenceRangeAssignmentStore(_ inner: MemoryLenientReferenceRangeAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientReferenceRangeAssignmentStore {
        return CachedLenientReferenceRangeAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient reference range assignments. Empty fields match all.
    final class LenientReferenceRangeAssignmentQuery {
        var label: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientReferenceRangeAssignment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientReferenceRangeAssignment]) -> [LenientReferenceRangeAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientReferenceRangeAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientReferenceRangeAssignments(_ store: any LenientReferenceRangeAssignmentStore, query: LenientReferenceRangeAssignmentQuery) -> [LenientReferenceRangeAssignment] {
        return query.apply(store.list())
    }
}
