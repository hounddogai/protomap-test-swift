import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional skill mix scores by code.
    protocol RegionalSkillMixScoreStore {
        func find(_ code: String) -> RegionalSkillMixScore?
        func save(_ item: RegionalSkillMixScore)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalSkillMixScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalSkillMixScoreStore: RegionalSkillMixScoreStore {
        var items: [String: RegionalSkillMixScore]
        var order: [String]

        init(items: [String: RegionalSkillMixScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalSkillMixScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalSkillMixScore) {
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

        func list() -> [RegionalSkillMixScore] {
            var out: [RegionalSkillMixScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalSkillMixScoreStore() -> any RegionalSkillMixScoreStore {
        return MemoryRegionalSkillMixScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalSkillMixScoreStore: RegionalSkillMixScoreStore {
        var inner: MemoryRegionalSkillMixScoreStore
        var cache: TTLCache<RegionalSkillMixScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalSkillMixScoreStore, cache: TTLCache<RegionalSkillMixScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalSkillMixScore? {
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

        func save(_ item: RegionalSkillMixScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalSkillMixScore] {
            return inner.list()
        }
    }

    static func newCachedRegionalSkillMixScoreStore(_ inner: MemoryRegionalSkillMixScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalSkillMixScoreStore {
        return CachedRegionalSkillMixScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional skill mix scores. Empty fields match all.
    final class RegionalSkillMixScoreQuery {
        var region: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRevision: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalSkillMixScore) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalSkillMixScore]) -> [RegionalSkillMixScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalSkillMixScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalSkillMixScores(_ store: any RegionalSkillMixScoreStore, query: RegionalSkillMixScoreQuery) -> [RegionalSkillMixScore] {
        return query.apply(store.list())
    }
}
