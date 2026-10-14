import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim assignments by code.
    protocol ClaimAssignmentStore {
        func find(_ code: String) -> ClaimAssignment?
        func save(_ item: ClaimAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimAssignmentStore: ClaimAssignmentStore {
        var items: [String: ClaimAssignment]
        var order: [String]

        init(items: [String: ClaimAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimAssignment) {
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

        func list() -> [ClaimAssignment] {
            var out: [ClaimAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimAssignmentStore() -> any ClaimAssignmentStore {
        return MemoryClaimAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimAssignmentStore: ClaimAssignmentStore {
        var inner: MemoryClaimAssignmentStore
        var cache: TTLCache<ClaimAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimAssignmentStore, cache: TTLCache<ClaimAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimAssignment? {
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

        func save(_ item: ClaimAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimAssignment] {
            return inner.list()
        }
    }

    static func newCachedClaimAssignmentStore(_ inner: MemoryClaimAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimAssignmentStore {
        return CachedClaimAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim assignments. Empty fields match all.
    final class ClaimAssignmentQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimAssignment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimAssignment]) -> [ClaimAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimAssignments(_ store: any ClaimAssignmentStore, query: ClaimAssignmentQuery) -> [ClaimAssignment] {
        return query.apply(store.list())
    }
}
