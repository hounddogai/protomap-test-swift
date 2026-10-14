import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual authorization rollups by code.
    protocol ManualAuthorizationRollupStore {
        func find(_ code: String) -> ManualAuthorizationRollup?
        func save(_ item: ManualAuthorizationRollup)
        func remove(_ code: String) -> Bool
        func list() -> [ManualAuthorizationRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualAuthorizationRollupStore: ManualAuthorizationRollupStore {
        var items: [String: ManualAuthorizationRollup]
        var order: [String]

        init(items: [String: ManualAuthorizationRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualAuthorizationRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualAuthorizationRollup) {
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

        func list() -> [ManualAuthorizationRollup] {
            var out: [ManualAuthorizationRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualAuthorizationRollupStore() -> any ManualAuthorizationRollupStore {
        return MemoryManualAuthorizationRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualAuthorizationRollupStore: ManualAuthorizationRollupStore {
        var inner: MemoryManualAuthorizationRollupStore
        var cache: TTLCache<ManualAuthorizationRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualAuthorizationRollupStore, cache: TTLCache<ManualAuthorizationRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualAuthorizationRollup? {
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

        func save(_ item: ManualAuthorizationRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualAuthorizationRollup] {
            return inner.list()
        }
    }

    static func newCachedManualAuthorizationRollupStore(_ inner: MemoryManualAuthorizationRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualAuthorizationRollupStore {
        return CachedManualAuthorizationRollupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual authorization rollups. Empty fields match all.
    final class ManualAuthorizationRollupQuery {
        var category: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRate: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualAuthorizationRollup) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualAuthorizationRollup]) -> [ManualAuthorizationRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualAuthorizationRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualAuthorizationRollups(_ store: any ManualAuthorizationRollupStore, query: ManualAuthorizationRollupQuery) -> [ManualAuthorizationRollup] {
        return query.apply(store.list())
    }
}
