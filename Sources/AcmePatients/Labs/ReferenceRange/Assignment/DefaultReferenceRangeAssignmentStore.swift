import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default reference range assignments by code.
    protocol DefaultReferenceRangeAssignmentStore {
        func find(_ code: String) -> DefaultReferenceRangeAssignment?
        func save(_ item: DefaultReferenceRangeAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultReferenceRangeAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultReferenceRangeAssignmentStore: DefaultReferenceRangeAssignmentStore {
        var items: [String: DefaultReferenceRangeAssignment]
        var order: [String]

        init(items: [String: DefaultReferenceRangeAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultReferenceRangeAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultReferenceRangeAssignment) {
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

        func list() -> [DefaultReferenceRangeAssignment] {
            var out: [DefaultReferenceRangeAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultReferenceRangeAssignmentStore() -> any DefaultReferenceRangeAssignmentStore {
        return MemoryDefaultReferenceRangeAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultReferenceRangeAssignmentStore: DefaultReferenceRangeAssignmentStore {
        var inner: MemoryDefaultReferenceRangeAssignmentStore
        var cache: TTLCache<DefaultReferenceRangeAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultReferenceRangeAssignmentStore, cache: TTLCache<DefaultReferenceRangeAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultReferenceRangeAssignment? {
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

        func save(_ item: DefaultReferenceRangeAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultReferenceRangeAssignment] {
            return inner.list()
        }
    }

    static func newCachedDefaultReferenceRangeAssignmentStore(_ inner: MemoryDefaultReferenceRangeAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultReferenceRangeAssignmentStore {
        return CachedDefaultReferenceRangeAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default reference range assignments. Empty fields match all.
    final class DefaultReferenceRangeAssignmentQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultReferenceRangeAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultReferenceRangeAssignment]) -> [DefaultReferenceRangeAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultReferenceRangeAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultReferenceRangeAssignments(_ store: any DefaultReferenceRangeAssignmentStore, query: DefaultReferenceRangeAssignmentQuery) -> [DefaultReferenceRangeAssignment] {
        return query.apply(store.list())
    }
}
