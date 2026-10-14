import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive risk score milestones by code.
    protocol AdaptiveRiskScoreMilestoneStore {
        func find(_ code: String) -> AdaptiveRiskScoreMilestone?
        func save(_ item: AdaptiveRiskScoreMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveRiskScoreMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveRiskScoreMilestoneStore: AdaptiveRiskScoreMilestoneStore {
        var items: [String: AdaptiveRiskScoreMilestone]
        var order: [String]

        init(items: [String: AdaptiveRiskScoreMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveRiskScoreMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveRiskScoreMilestone) {
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

        func list() -> [AdaptiveRiskScoreMilestone] {
            var out: [AdaptiveRiskScoreMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveRiskScoreMilestoneStore() -> any AdaptiveRiskScoreMilestoneStore {
        return MemoryAdaptiveRiskScoreMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveRiskScoreMilestoneStore: AdaptiveRiskScoreMilestoneStore {
        var inner: MemoryAdaptiveRiskScoreMilestoneStore
        var cache: TTLCache<AdaptiveRiskScoreMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveRiskScoreMilestoneStore, cache: TTLCache<AdaptiveRiskScoreMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveRiskScoreMilestone? {
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

        func save(_ item: AdaptiveRiskScoreMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveRiskScoreMilestone] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveRiskScoreMilestoneStore(_ inner: MemoryAdaptiveRiskScoreMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveRiskScoreMilestoneStore {
        return CachedAdaptiveRiskScoreMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive risk score milestones. Empty fields match all.
    final class AdaptiveRiskScoreMilestoneQuery {
        var country: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minSequence: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveRiskScoreMilestone) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveRiskScoreMilestone]) -> [AdaptiveRiskScoreMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveRiskScoreMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveRiskScoreMilestones(_ store: any AdaptiveRiskScoreMilestoneStore, query: AdaptiveRiskScoreMilestoneQuery) -> [AdaptiveRiskScoreMilestone] {
        return query.apply(store.list())
    }
}
