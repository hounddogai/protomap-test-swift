import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive reference range milestones by code.
    protocol AdaptiveReferenceRangeMilestoneStore {
        func find(_ code: String) -> AdaptiveReferenceRangeMilestone?
        func save(_ item: AdaptiveReferenceRangeMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveReferenceRangeMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveReferenceRangeMilestoneStore: AdaptiveReferenceRangeMilestoneStore {
        var items: [String: AdaptiveReferenceRangeMilestone]
        var order: [String]

        init(items: [String: AdaptiveReferenceRangeMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveReferenceRangeMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveReferenceRangeMilestone) {
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

        func list() -> [AdaptiveReferenceRangeMilestone] {
            var out: [AdaptiveReferenceRangeMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveReferenceRangeMilestoneStore() -> any AdaptiveReferenceRangeMilestoneStore {
        return MemoryAdaptiveReferenceRangeMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveReferenceRangeMilestoneStore: AdaptiveReferenceRangeMilestoneStore {
        var inner: MemoryAdaptiveReferenceRangeMilestoneStore
        var cache: TTLCache<AdaptiveReferenceRangeMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveReferenceRangeMilestoneStore, cache: TTLCache<AdaptiveReferenceRangeMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveReferenceRangeMilestone? {
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

        func save(_ item: AdaptiveReferenceRangeMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveReferenceRangeMilestone] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveReferenceRangeMilestoneStore(_ inner: MemoryAdaptiveReferenceRangeMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveReferenceRangeMilestoneStore {
        return CachedAdaptiveReferenceRangeMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive reference range milestones. Empty fields match all.
    final class AdaptiveReferenceRangeMilestoneQuery {
        var region: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveReferenceRangeMilestone) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveReferenceRangeMilestone]) -> [AdaptiveReferenceRangeMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveReferenceRangeMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveReferenceRangeMilestones(_ store: any AdaptiveReferenceRangeMilestoneStore, query: AdaptiveReferenceRangeMilestoneQuery) -> [AdaptiveReferenceRangeMilestone] {
        return query.apply(store.list())
    }
}
