import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps fallback care protocol assignments by code.
    protocol FallbackCareProtocolAssignmentStore {
        func find(_ code: String) -> FallbackCareProtocolAssignment?
        func save(_ item: FallbackCareProtocolAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCareProtocolAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCareProtocolAssignmentStore: FallbackCareProtocolAssignmentStore {
        var items: [String: FallbackCareProtocolAssignment]
        var order: [String]

        init(items: [String: FallbackCareProtocolAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCareProtocolAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCareProtocolAssignment) {
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

        func list() -> [FallbackCareProtocolAssignment] {
            var out: [FallbackCareProtocolAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCareProtocolAssignmentStore() -> any FallbackCareProtocolAssignmentStore {
        return MemoryFallbackCareProtocolAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCareProtocolAssignmentStore: FallbackCareProtocolAssignmentStore {
        var inner: MemoryFallbackCareProtocolAssignmentStore
        var cache: TTLCache<FallbackCareProtocolAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCareProtocolAssignmentStore, cache: TTLCache<FallbackCareProtocolAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCareProtocolAssignment? {
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

        func save(_ item: FallbackCareProtocolAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCareProtocolAssignment] {
            return inner.list()
        }
    }

    static func newCachedFallbackCareProtocolAssignmentStore(_ inner: MemoryFallbackCareProtocolAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCareProtocolAssignmentStore {
        return CachedFallbackCareProtocolAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback care protocol assignments. Empty fields match all.
    final class FallbackCareProtocolAssignmentQuery {
        var ward: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minBudget: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCareProtocolAssignment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCareProtocolAssignment]) -> [FallbackCareProtocolAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCareProtocolAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCareProtocolAssignments(_ store: any FallbackCareProtocolAssignmentStore, query: FallbackCareProtocolAssignmentQuery) -> [FallbackCareProtocolAssignment] {
        return query.apply(store.list())
    }
}
