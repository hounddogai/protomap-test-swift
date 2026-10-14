import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback assessment milestones by code.
    protocol FallbackAssessmentMilestoneStore {
        func find(_ code: String) -> FallbackAssessmentMilestone?
        func save(_ item: FallbackAssessmentMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackAssessmentMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackAssessmentMilestoneStore: FallbackAssessmentMilestoneStore {
        var items: [String: FallbackAssessmentMilestone]
        var order: [String]

        init(items: [String: FallbackAssessmentMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackAssessmentMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackAssessmentMilestone) {
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

        func list() -> [FallbackAssessmentMilestone] {
            var out: [FallbackAssessmentMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackAssessmentMilestoneStore() -> any FallbackAssessmentMilestoneStore {
        return MemoryFallbackAssessmentMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackAssessmentMilestoneStore: FallbackAssessmentMilestoneStore {
        var inner: MemoryFallbackAssessmentMilestoneStore
        var cache: TTLCache<FallbackAssessmentMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackAssessmentMilestoneStore, cache: TTLCache<FallbackAssessmentMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackAssessmentMilestone? {
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

        func save(_ item: FallbackAssessmentMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackAssessmentMilestone] {
            return inner.list()
        }
    }

    static func newCachedFallbackAssessmentMilestoneStore(_ inner: MemoryFallbackAssessmentMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackAssessmentMilestoneStore {
        return CachedFallbackAssessmentMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback assessment milestones. Empty fields match all.
    final class FallbackAssessmentMilestoneQuery {
        var region: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackAssessmentMilestone) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackAssessmentMilestone]) -> [FallbackAssessmentMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackAssessmentMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackAssessmentMilestones(_ store: any FallbackAssessmentMilestoneStore, query: FallbackAssessmentMilestoneQuery) -> [FallbackAssessmentMilestone] {
        return query.apply(store.list())
    }
}
