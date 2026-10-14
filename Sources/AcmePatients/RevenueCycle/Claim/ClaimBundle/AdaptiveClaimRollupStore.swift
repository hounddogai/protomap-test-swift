import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive claim rollups by code.
    protocol AdaptiveClaimRollupStore {
        func find(_ code: String) -> AdaptiveClaimRollup?
        func save(_ item: AdaptiveClaimRollup)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveClaimRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveClaimRollupStore: AdaptiveClaimRollupStore {
        var items: [String: AdaptiveClaimRollup]
        var order: [String]

        init(items: [String: AdaptiveClaimRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveClaimRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveClaimRollup) {
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

        func list() -> [AdaptiveClaimRollup] {
            var out: [AdaptiveClaimRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveClaimRollupStore() -> any AdaptiveClaimRollupStore {
        return MemoryAdaptiveClaimRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveClaimRollupStore: AdaptiveClaimRollupStore {
        var inner: MemoryAdaptiveClaimRollupStore
        var cache: TTLCache<AdaptiveClaimRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveClaimRollupStore, cache: TTLCache<AdaptiveClaimRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveClaimRollup? {
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

        func save(_ item: AdaptiveClaimRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveClaimRollup] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveClaimRollupStore(_ inner: MemoryAdaptiveClaimRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveClaimRollupStore {
        return CachedAdaptiveClaimRollupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive claim rollups. Empty fields match all.
    final class AdaptiveClaimRollupQuery {
        var locale: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveClaimRollup) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [AdaptiveClaimRollup]) -> [AdaptiveClaimRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveClaimRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveClaimRollups(_ store: any AdaptiveClaimRollupStore, query: AdaptiveClaimRollupQuery) -> [AdaptiveClaimRollup] {
        return query.apply(store.list())
    }
}
