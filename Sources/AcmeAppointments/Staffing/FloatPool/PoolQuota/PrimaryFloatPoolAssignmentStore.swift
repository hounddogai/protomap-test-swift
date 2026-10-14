import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary float pool assignments by code.
    protocol PrimaryFloatPoolAssignmentStore {
        func find(_ code: String) -> PrimaryFloatPoolAssignment?
        func save(_ item: PrimaryFloatPoolAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryFloatPoolAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryFloatPoolAssignmentStore: PrimaryFloatPoolAssignmentStore {
        var items: [String: PrimaryFloatPoolAssignment]
        var order: [String]

        init(items: [String: PrimaryFloatPoolAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryFloatPoolAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryFloatPoolAssignment) {
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

        func list() -> [PrimaryFloatPoolAssignment] {
            var out: [PrimaryFloatPoolAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryFloatPoolAssignmentStore() -> any PrimaryFloatPoolAssignmentStore {
        return MemoryPrimaryFloatPoolAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryFloatPoolAssignmentStore: PrimaryFloatPoolAssignmentStore {
        var inner: MemoryPrimaryFloatPoolAssignmentStore
        var cache: TTLCache<PrimaryFloatPoolAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryFloatPoolAssignmentStore, cache: TTLCache<PrimaryFloatPoolAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryFloatPoolAssignment? {
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

        func save(_ item: PrimaryFloatPoolAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryFloatPoolAssignment] {
            return inner.list()
        }
    }

    static func newCachedPrimaryFloatPoolAssignmentStore(_ inner: MemoryPrimaryFloatPoolAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryFloatPoolAssignmentStore {
        return CachedPrimaryFloatPoolAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary float pool assignments. Empty fields match all.
    final class PrimaryFloatPoolAssignmentQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryFloatPoolAssignment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryFloatPoolAssignment]) -> [PrimaryFloatPoolAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryFloatPoolAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryFloatPoolAssignments(_ store: any PrimaryFloatPoolAssignmentStore, query: PrimaryFloatPoolAssignmentQuery) -> [PrimaryFloatPoolAssignment] {
        return query.apply(store.list())
    }
}
