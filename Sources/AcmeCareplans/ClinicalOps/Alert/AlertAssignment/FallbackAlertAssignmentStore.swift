import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps fallback alert assignments by code.
    protocol FallbackAlertAssignmentStore {
        func find(_ code: String) -> FallbackAlertAssignment?
        func save(_ item: FallbackAlertAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackAlertAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackAlertAssignmentStore: FallbackAlertAssignmentStore {
        var items: [String: FallbackAlertAssignment]
        var order: [String]

        init(items: [String: FallbackAlertAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackAlertAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackAlertAssignment) {
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

        func list() -> [FallbackAlertAssignment] {
            var out: [FallbackAlertAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackAlertAssignmentStore() -> any FallbackAlertAssignmentStore {
        return MemoryFallbackAlertAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackAlertAssignmentStore: FallbackAlertAssignmentStore {
        var inner: MemoryFallbackAlertAssignmentStore
        var cache: TTLCache<FallbackAlertAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackAlertAssignmentStore, cache: TTLCache<FallbackAlertAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackAlertAssignment? {
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

        func save(_ item: FallbackAlertAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackAlertAssignment] {
            return inner.list()
        }
    }

    static func newCachedFallbackAlertAssignmentStore(_ inner: MemoryFallbackAlertAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackAlertAssignmentStore {
        return CachedFallbackAlertAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback alert assignments. Empty fields match all.
    final class FallbackAlertAssignmentQuery {
        var facility: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackAlertAssignment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackAlertAssignment]) -> [FallbackAlertAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackAlertAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackAlertAssignments(_ store: any FallbackAlertAssignmentStore, query: FallbackAlertAssignmentQuery) -> [FallbackAlertAssignment] {
        return query.apply(store.list())
    }
}
