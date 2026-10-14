import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global skill mix estimates by code.
    protocol GlobalSkillMixEstimateStore {
        func find(_ code: String) -> GlobalSkillMixEstimate?
        func save(_ item: GlobalSkillMixEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalSkillMixEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalSkillMixEstimateStore: GlobalSkillMixEstimateStore {
        var items: [String: GlobalSkillMixEstimate]
        var order: [String]

        init(items: [String: GlobalSkillMixEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalSkillMixEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalSkillMixEstimate) {
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

        func list() -> [GlobalSkillMixEstimate] {
            var out: [GlobalSkillMixEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalSkillMixEstimateStore() -> any GlobalSkillMixEstimateStore {
        return MemoryGlobalSkillMixEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalSkillMixEstimateStore: GlobalSkillMixEstimateStore {
        var inner: MemoryGlobalSkillMixEstimateStore
        var cache: TTLCache<GlobalSkillMixEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalSkillMixEstimateStore, cache: TTLCache<GlobalSkillMixEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalSkillMixEstimate? {
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

        func save(_ item: GlobalSkillMixEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalSkillMixEstimate] {
            return inner.list()
        }
    }

    static func newCachedGlobalSkillMixEstimateStore(_ inner: MemoryGlobalSkillMixEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalSkillMixEstimateStore {
        return CachedGlobalSkillMixEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global skill mix estimates. Empty fields match all.
    final class GlobalSkillMixEstimateQuery {
        var title: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minBudget: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalSkillMixEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [GlobalSkillMixEstimate]) -> [GlobalSkillMixEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalSkillMixEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalSkillMixEstimates(_ store: any GlobalSkillMixEstimateStore, query: GlobalSkillMixEstimateQuery) -> [GlobalSkillMixEstimate] {
        return query.apply(store.list())
    }
}
