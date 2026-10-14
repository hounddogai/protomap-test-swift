import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered claim baselines by code.
    protocol TieredClaimBaselineStore {
        func find(_ code: String) -> TieredClaimBaseline?
        func save(_ item: TieredClaimBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [TieredClaimBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredClaimBaselineStore: TieredClaimBaselineStore {
        var items: [String: TieredClaimBaseline]
        var order: [String]

        init(items: [String: TieredClaimBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredClaimBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredClaimBaseline) {
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

        func list() -> [TieredClaimBaseline] {
            var out: [TieredClaimBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredClaimBaselineStore() -> any TieredClaimBaselineStore {
        return MemoryTieredClaimBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredClaimBaselineStore: TieredClaimBaselineStore {
        var inner: MemoryTieredClaimBaselineStore
        var cache: TTLCache<TieredClaimBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredClaimBaselineStore, cache: TTLCache<TieredClaimBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredClaimBaseline? {
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

        func save(_ item: TieredClaimBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredClaimBaseline] {
            return inner.list()
        }
    }

    static func newCachedTieredClaimBaselineStore(_ inner: MemoryTieredClaimBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredClaimBaselineStore {
        return CachedTieredClaimBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered claim baselines. Empty fields match all.
    final class TieredClaimBaselineQuery {
        var country: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredClaimBaseline) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [TieredClaimBaseline]) -> [TieredClaimBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredClaimBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredClaimBaselines(_ store: any TieredClaimBaselineStore, query: TieredClaimBaselineQuery) -> [TieredClaimBaseline] {
        return query.apply(store.list())
    }
}
