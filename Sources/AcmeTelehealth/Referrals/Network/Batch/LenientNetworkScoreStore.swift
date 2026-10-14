import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps lenient network scores by code.
    protocol LenientNetworkScoreStore {
        func find(_ code: String) -> LenientNetworkScore?
        func save(_ item: LenientNetworkScore)
        func remove(_ code: String) -> Bool
        func list() -> [LenientNetworkScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientNetworkScoreStore: LenientNetworkScoreStore {
        var items: [String: LenientNetworkScore]
        var order: [String]

        init(items: [String: LenientNetworkScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientNetworkScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientNetworkScore) {
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

        func list() -> [LenientNetworkScore] {
            var out: [LenientNetworkScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientNetworkScoreStore() -> any LenientNetworkScoreStore {
        return MemoryLenientNetworkScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientNetworkScoreStore: LenientNetworkScoreStore {
        var inner: MemoryLenientNetworkScoreStore
        var cache: TTLCache<LenientNetworkScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientNetworkScoreStore, cache: TTLCache<LenientNetworkScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientNetworkScore? {
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

        func save(_ item: LenientNetworkScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientNetworkScore] {
            return inner.list()
        }
    }

    static func newCachedLenientNetworkScoreStore(_ inner: MemoryLenientNetworkScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientNetworkScoreStore {
        return CachedLenientNetworkScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient network scores. Empty fields match all.
    final class LenientNetworkScoreQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientNetworkScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientNetworkScore]) -> [LenientNetworkScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientNetworkScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientNetworkScores(_ store: any LenientNetworkScoreStore, query: LenientNetworkScoreQuery) -> [LenientNetworkScore] {
        return query.apply(store.list())
    }
}
