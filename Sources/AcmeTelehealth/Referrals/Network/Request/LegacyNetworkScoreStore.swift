import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps legacy network scores by code.
    protocol LegacyNetworkScoreStore {
        func find(_ code: String) -> LegacyNetworkScore?
        func save(_ item: LegacyNetworkScore)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyNetworkScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyNetworkScoreStore: LegacyNetworkScoreStore {
        var items: [String: LegacyNetworkScore]
        var order: [String]

        init(items: [String: LegacyNetworkScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyNetworkScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyNetworkScore) {
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

        func list() -> [LegacyNetworkScore] {
            var out: [LegacyNetworkScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyNetworkScoreStore() -> any LegacyNetworkScoreStore {
        return MemoryLegacyNetworkScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyNetworkScoreStore: LegacyNetworkScoreStore {
        var inner: MemoryLegacyNetworkScoreStore
        var cache: TTLCache<LegacyNetworkScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyNetworkScoreStore, cache: TTLCache<LegacyNetworkScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyNetworkScore? {
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

        func save(_ item: LegacyNetworkScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyNetworkScore] {
            return inner.list()
        }
    }

    static func newCachedLegacyNetworkScoreStore(_ inner: MemoryLegacyNetworkScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyNetworkScoreStore {
        return CachedLegacyNetworkScoreStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy network scores. Empty fields match all.
    final class LegacyNetworkScoreQuery {
        var title: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minWeight: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyNetworkScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyNetworkScore]) -> [LegacyNetworkScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyNetworkScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyNetworkScores(_ store: any LegacyNetworkScoreStore, query: LegacyNetworkScoreQuery) -> [LegacyNetworkScore] {
        return query.apply(store.list())
    }
}
