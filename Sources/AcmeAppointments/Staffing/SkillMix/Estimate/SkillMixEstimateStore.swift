import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix estimates by code.
    protocol SkillMixEstimateStore {
        func find(_ code: String) -> SkillMixEstimate?
        func save(_ item: SkillMixEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixEstimateStore: SkillMixEstimateStore {
        var items: [String: SkillMixEstimate]
        var order: [String]

        init(items: [String: SkillMixEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixEstimate) {
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

        func list() -> [SkillMixEstimate] {
            var out: [SkillMixEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixEstimateStore() -> any SkillMixEstimateStore {
        return MemorySkillMixEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixEstimateStore: SkillMixEstimateStore {
        var inner: MemorySkillMixEstimateStore
        var cache: TTLCache<SkillMixEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixEstimateStore, cache: TTLCache<SkillMixEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixEstimate? {
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

        func save(_ item: SkillMixEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixEstimate] {
            return inner.list()
        }
    }

    static func newCachedSkillMixEstimateStore(_ inner: MemorySkillMixEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixEstimateStore {
        return CachedSkillMixEstimateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix estimates. Empty fields match all.
    final class SkillMixEstimateQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixEstimate]) -> [SkillMixEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixEstimates(_ store: any SkillMixEstimateStore, query: SkillMixEstimateQuery) -> [SkillMixEstimate] {
        return query.apply(store.list())
    }
}
