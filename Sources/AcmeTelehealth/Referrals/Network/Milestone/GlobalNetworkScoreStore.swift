import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global network scores by code.
    protocol GlobalNetworkScoreStore {
        func find(_ code: String) -> GlobalNetworkScore?
        func save(_ item: GlobalNetworkScore)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalNetworkScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalNetworkScoreStore: GlobalNetworkScoreStore {
        var items: [String: GlobalNetworkScore]
        var order: [String]

        init(items: [String: GlobalNetworkScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalNetworkScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalNetworkScore) {
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

        func list() -> [GlobalNetworkScore] {
            var out: [GlobalNetworkScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalNetworkScoreStore() -> any GlobalNetworkScoreStore {
        return MemoryGlobalNetworkScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalNetworkScoreStore: GlobalNetworkScoreStore {
        var inner: MemoryGlobalNetworkScoreStore
        var cache: TTLCache<GlobalNetworkScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalNetworkScoreStore, cache: TTLCache<GlobalNetworkScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalNetworkScore? {
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

        func save(_ item: GlobalNetworkScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalNetworkScore] {
            return inner.list()
        }
    }

    static func newCachedGlobalNetworkScoreStore(_ inner: MemoryGlobalNetworkScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalNetworkScoreStore {
        return CachedGlobalNetworkScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global network scores. Empty fields match all.
    final class GlobalNetworkScoreQuery {
        var unit: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minBudget: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalNetworkScore) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [GlobalNetworkScore]) -> [GlobalNetworkScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalNetworkScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalNetworkScores(_ store: any GlobalNetworkScoreStore, query: GlobalNetworkScoreQuery) -> [GlobalNetworkScore] {
        return query.apply(store.list())
    }
}
