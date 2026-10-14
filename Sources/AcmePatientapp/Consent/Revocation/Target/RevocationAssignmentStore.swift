import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation assignments by code.
    protocol RevocationAssignmentStore {
        func find(_ code: String) -> RevocationAssignment?
        func save(_ item: RevocationAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationAssignmentStore: RevocationAssignmentStore {
        var items: [String: RevocationAssignment]
        var order: [String]

        init(items: [String: RevocationAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationAssignment) {
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

        func list() -> [RevocationAssignment] {
            var out: [RevocationAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationAssignmentStore() -> any RevocationAssignmentStore {
        return MemoryRevocationAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationAssignmentStore: RevocationAssignmentStore {
        var inner: MemoryRevocationAssignmentStore
        var cache: TTLCache<RevocationAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationAssignmentStore, cache: TTLCache<RevocationAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationAssignment? {
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

        func save(_ item: RevocationAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationAssignment] {
            return inner.list()
        }
    }

    static func newCachedRevocationAssignmentStore(_ inner: MemoryRevocationAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationAssignmentStore {
        return CachedRevocationAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation assignments. Empty fields match all.
    final class RevocationAssignmentQuery {
        var facility: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationAssignment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationAssignment]) -> [RevocationAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationAssignments(_ store: any RevocationAssignmentStore, query: RevocationAssignmentQuery) -> [RevocationAssignment] {
        return query.apply(store.list())
    }
}
