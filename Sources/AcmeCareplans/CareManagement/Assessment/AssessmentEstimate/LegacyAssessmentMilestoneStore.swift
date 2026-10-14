import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps legacy assessment milestones by code.
    protocol LegacyAssessmentMilestoneStore {
        func find(_ code: String) -> LegacyAssessmentMilestone?
        func save(_ item: LegacyAssessmentMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAssessmentMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAssessmentMilestoneStore: LegacyAssessmentMilestoneStore {
        var items: [String: LegacyAssessmentMilestone]
        var order: [String]

        init(items: [String: LegacyAssessmentMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAssessmentMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAssessmentMilestone) {
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

        func list() -> [LegacyAssessmentMilestone] {
            var out: [LegacyAssessmentMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAssessmentMilestoneStore() -> any LegacyAssessmentMilestoneStore {
        return MemoryLegacyAssessmentMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAssessmentMilestoneStore: LegacyAssessmentMilestoneStore {
        var inner: MemoryLegacyAssessmentMilestoneStore
        var cache: TTLCache<LegacyAssessmentMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAssessmentMilestoneStore, cache: TTLCache<LegacyAssessmentMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAssessmentMilestone? {
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

        func save(_ item: LegacyAssessmentMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAssessmentMilestone] {
            return inner.list()
        }
    }

    static func newCachedLegacyAssessmentMilestoneStore(_ inner: MemoryLegacyAssessmentMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAssessmentMilestoneStore {
        return CachedLegacyAssessmentMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy assessment milestones. Empty fields match all.
    final class LegacyAssessmentMilestoneQuery {
        var region: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAssessmentMilestone) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [LegacyAssessmentMilestone]) -> [LegacyAssessmentMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAssessmentMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAssessmentMilestones(_ store: any LegacyAssessmentMilestoneStore, query: LegacyAssessmentMilestoneQuery) -> [LegacyAssessmentMilestone] {
        return query.apply(store.list())
    }
}
