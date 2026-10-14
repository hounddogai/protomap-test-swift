import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps default claim rollups by code.
    protocol DefaultClaimRollupStore {
        func find(_ code: String) -> DefaultClaimRollup?
        func save(_ item: DefaultClaimRollup)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultClaimRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultClaimRollupStore: DefaultClaimRollupStore {
        var items: [String: DefaultClaimRollup]
        var order: [String]

        init(items: [String: DefaultClaimRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultClaimRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultClaimRollup) {
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

        func list() -> [DefaultClaimRollup] {
            var out: [DefaultClaimRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultClaimRollupStore() -> any DefaultClaimRollupStore {
        return MemoryDefaultClaimRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultClaimRollupStore: DefaultClaimRollupStore {
        var inner: MemoryDefaultClaimRollupStore
        var cache: TTLCache<DefaultClaimRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultClaimRollupStore, cache: TTLCache<DefaultClaimRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultClaimRollup? {
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

        func save(_ item: DefaultClaimRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultClaimRollup] {
            return inner.list()
        }
    }

    static func newCachedDefaultClaimRollupStore(_ inner: MemoryDefaultClaimRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultClaimRollupStore {
        return CachedDefaultClaimRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default claim rollups. Empty fields match all.
    final class DefaultClaimRollupQuery {
        var category: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultClaimRollup) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [DefaultClaimRollup]) -> [DefaultClaimRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultClaimRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultClaimRollups(_ store: any DefaultClaimRollupStore, query: DefaultClaimRollupQuery) -> [DefaultClaimRollup] {
        return query.apply(store.list())
    }
}
