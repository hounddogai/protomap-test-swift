import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary skill mix scores by code.
    protocol PrimarySkillMixScoreStore {
        func find(_ code: String) -> PrimarySkillMixScore?
        func save(_ item: PrimarySkillMixScore)
        func remove(_ code: String) -> Bool
        func list() -> [PrimarySkillMixScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimarySkillMixScoreStore: PrimarySkillMixScoreStore {
        var items: [String: PrimarySkillMixScore]
        var order: [String]

        init(items: [String: PrimarySkillMixScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimarySkillMixScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimarySkillMixScore) {
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

        func list() -> [PrimarySkillMixScore] {
            var out: [PrimarySkillMixScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimarySkillMixScoreStore() -> any PrimarySkillMixScoreStore {
        return MemoryPrimarySkillMixScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimarySkillMixScoreStore: PrimarySkillMixScoreStore {
        var inner: MemoryPrimarySkillMixScoreStore
        var cache: TTLCache<PrimarySkillMixScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimarySkillMixScoreStore, cache: TTLCache<PrimarySkillMixScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimarySkillMixScore? {
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

        func save(_ item: PrimarySkillMixScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimarySkillMixScore] {
            return inner.list()
        }
    }

    static func newCachedPrimarySkillMixScoreStore(_ inner: MemoryPrimarySkillMixScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimarySkillMixScoreStore {
        return CachedPrimarySkillMixScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary skill mix scores. Empty fields match all.
    final class PrimarySkillMixScoreQuery {
        var facility: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCopay: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimarySkillMixScore) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimarySkillMixScore]) -> [PrimarySkillMixScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimarySkillMixScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimarySkillMixScores(_ store: any PrimarySkillMixScoreStore, query: PrimarySkillMixScoreQuery) -> [PrimarySkillMixScore] {
        return query.apply(store.list())
    }
}
