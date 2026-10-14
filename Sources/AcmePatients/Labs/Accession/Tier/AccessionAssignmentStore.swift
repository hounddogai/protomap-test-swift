import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession assignments by code.
    protocol AccessionAssignmentStore {
        func find(_ code: String) -> AccessionAssignment?
        func save(_ item: AccessionAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionAssignmentStore: AccessionAssignmentStore {
        var items: [String: AccessionAssignment]
        var order: [String]

        init(items: [String: AccessionAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionAssignment) {
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

        func list() -> [AccessionAssignment] {
            var out: [AccessionAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionAssignmentStore() -> any AccessionAssignmentStore {
        return MemoryAccessionAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionAssignmentStore: AccessionAssignmentStore {
        var inner: MemoryAccessionAssignmentStore
        var cache: TTLCache<AccessionAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionAssignmentStore, cache: TTLCache<AccessionAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionAssignment? {
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

        func save(_ item: AccessionAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionAssignment] {
            return inner.list()
        }
    }

    static func newCachedAccessionAssignmentStore(_ inner: MemoryAccessionAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionAssignmentStore {
        return CachedAccessionAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession assignments. Empty fields match all.
    final class AccessionAssignmentQuery {
        var source: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRetries: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionAssignment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionAssignment]) -> [AccessionAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionAssignments(_ store: any AccessionAssignmentStore, query: AccessionAssignmentQuery) -> [AccessionAssignment] {
        return query.apply(store.list())
    }
}
