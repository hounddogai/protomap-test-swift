import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback eligibility assignments by code.
    protocol FallbackEligibilityAssignmentStore {
        func find(_ code: String) -> FallbackEligibilityAssignment?
        func save(_ item: FallbackEligibilityAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackEligibilityAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackEligibilityAssignmentStore: FallbackEligibilityAssignmentStore {
        var items: [String: FallbackEligibilityAssignment]
        var order: [String]

        init(items: [String: FallbackEligibilityAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackEligibilityAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackEligibilityAssignment) {
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

        func list() -> [FallbackEligibilityAssignment] {
            var out: [FallbackEligibilityAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackEligibilityAssignmentStore() -> any FallbackEligibilityAssignmentStore {
        return MemoryFallbackEligibilityAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackEligibilityAssignmentStore: FallbackEligibilityAssignmentStore {
        var inner: MemoryFallbackEligibilityAssignmentStore
        var cache: TTLCache<FallbackEligibilityAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackEligibilityAssignmentStore, cache: TTLCache<FallbackEligibilityAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackEligibilityAssignment? {
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

        func save(_ item: FallbackEligibilityAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackEligibilityAssignment] {
            return inner.list()
        }
    }

    static func newCachedFallbackEligibilityAssignmentStore(_ inner: MemoryFallbackEligibilityAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackEligibilityAssignmentStore {
        return CachedFallbackEligibilityAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback eligibility assignments. Empty fields match all.
    final class FallbackEligibilityAssignmentQuery {
        var facility: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackEligibilityAssignment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackEligibilityAssignment]) -> [FallbackEligibilityAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackEligibilityAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackEligibilityAssignments(_ store: any FallbackEligibilityAssignmentStore, query: FallbackEligibilityAssignmentQuery) -> [FallbackEligibilityAssignment] {
        return query.apply(store.list())
    }
}
