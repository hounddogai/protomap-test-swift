import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual closure scores by code.
    protocol ManualClosureScoreStore {
        func find(_ code: String) -> ManualClosureScore?
        func save(_ item: ManualClosureScore)
        func remove(_ code: String) -> Bool
        func list() -> [ManualClosureScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualClosureScoreStore: ManualClosureScoreStore {
        var items: [String: ManualClosureScore]
        var order: [String]

        init(items: [String: ManualClosureScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualClosureScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualClosureScore) {
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

        func list() -> [ManualClosureScore] {
            var out: [ManualClosureScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualClosureScoreStore() -> any ManualClosureScoreStore {
        return MemoryManualClosureScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualClosureScoreStore: ManualClosureScoreStore {
        var inner: MemoryManualClosureScoreStore
        var cache: TTLCache<ManualClosureScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualClosureScoreStore, cache: TTLCache<ManualClosureScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualClosureScore? {
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

        func save(_ item: ManualClosureScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualClosureScore] {
            return inner.list()
        }
    }

    static func newCachedManualClosureScoreStore(_ inner: MemoryManualClosureScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualClosureScoreStore {
        return CachedManualClosureScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual closure scores. Empty fields match all.
    final class ManualClosureScoreQuery {
        var region: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualClosureScore) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualClosureScore]) -> [ManualClosureScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualClosureScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualClosureScores(_ store: any ManualClosureScoreStore, query: ManualClosureScoreQuery) -> [ManualClosureScore] {
        return query.apply(store.list())
    }
}
