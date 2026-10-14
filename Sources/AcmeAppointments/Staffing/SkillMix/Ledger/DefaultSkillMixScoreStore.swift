import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default skill mix scores by code.
    protocol DefaultSkillMixScoreStore {
        func find(_ code: String) -> DefaultSkillMixScore?
        func save(_ item: DefaultSkillMixScore)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultSkillMixScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultSkillMixScoreStore: DefaultSkillMixScoreStore {
        var items: [String: DefaultSkillMixScore]
        var order: [String]

        init(items: [String: DefaultSkillMixScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultSkillMixScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultSkillMixScore) {
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

        func list() -> [DefaultSkillMixScore] {
            var out: [DefaultSkillMixScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultSkillMixScoreStore() -> any DefaultSkillMixScoreStore {
        return MemoryDefaultSkillMixScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultSkillMixScoreStore: DefaultSkillMixScoreStore {
        var inner: MemoryDefaultSkillMixScoreStore
        var cache: TTLCache<DefaultSkillMixScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultSkillMixScoreStore, cache: TTLCache<DefaultSkillMixScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultSkillMixScore? {
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

        func save(_ item: DefaultSkillMixScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultSkillMixScore] {
            return inner.list()
        }
    }

    static func newCachedDefaultSkillMixScoreStore(_ inner: MemoryDefaultSkillMixScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultSkillMixScoreStore {
        return CachedDefaultSkillMixScoreStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default skill mix scores. Empty fields match all.
    final class DefaultSkillMixScoreQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultSkillMixScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [DefaultSkillMixScore]) -> [DefaultSkillMixScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultSkillMixScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultSkillMixScores(_ store: any DefaultSkillMixScoreStore, query: DefaultSkillMixScoreQuery) -> [DefaultSkillMixScore] {
        return query.apply(store.list())
    }
}
