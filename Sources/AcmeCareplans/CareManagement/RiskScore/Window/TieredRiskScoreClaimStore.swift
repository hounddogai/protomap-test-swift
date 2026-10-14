import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps tiered risk score claims by code.
    protocol TieredRiskScoreClaimStore {
        func find(_ code: String) -> TieredRiskScoreClaim?
        func save(_ item: TieredRiskScoreClaim)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRiskScoreClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRiskScoreClaimStore: TieredRiskScoreClaimStore {
        var items: [String: TieredRiskScoreClaim]
        var order: [String]

        init(items: [String: TieredRiskScoreClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRiskScoreClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRiskScoreClaim) {
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

        func list() -> [TieredRiskScoreClaim] {
            var out: [TieredRiskScoreClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRiskScoreClaimStore() -> any TieredRiskScoreClaimStore {
        return MemoryTieredRiskScoreClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRiskScoreClaimStore: TieredRiskScoreClaimStore {
        var inner: MemoryTieredRiskScoreClaimStore
        var cache: TTLCache<TieredRiskScoreClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRiskScoreClaimStore, cache: TTLCache<TieredRiskScoreClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRiskScoreClaim? {
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

        func save(_ item: TieredRiskScoreClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRiskScoreClaim] {
            return inner.list()
        }
    }

    static func newCachedTieredRiskScoreClaimStore(_ inner: MemoryTieredRiskScoreClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRiskScoreClaimStore {
        return CachedTieredRiskScoreClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered risk score claims. Empty fields match all.
    final class TieredRiskScoreClaimQuery {
        var channel: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRiskScoreClaim) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredRiskScoreClaim]) -> [TieredRiskScoreClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRiskScoreClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRiskScoreClaims(_ store: any TieredRiskScoreClaimStore, query: TieredRiskScoreClaimQuery) -> [TieredRiskScoreClaim] {
        return query.apply(store.list())
    }
}
