import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional network bundles by code.
    protocol RegionalNetworkBundleStore {
        func find(_ code: String) -> RegionalNetworkBundle?
        func save(_ item: RegionalNetworkBundle)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalNetworkBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalNetworkBundleStore: RegionalNetworkBundleStore {
        var items: [String: RegionalNetworkBundle]
        var order: [String]

        init(items: [String: RegionalNetworkBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalNetworkBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalNetworkBundle) {
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

        func list() -> [RegionalNetworkBundle] {
            var out: [RegionalNetworkBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalNetworkBundleStore() -> any RegionalNetworkBundleStore {
        return MemoryRegionalNetworkBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalNetworkBundleStore: RegionalNetworkBundleStore {
        var inner: MemoryRegionalNetworkBundleStore
        var cache: TTLCache<RegionalNetworkBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalNetworkBundleStore, cache: TTLCache<RegionalNetworkBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalNetworkBundle? {
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

        func save(_ item: RegionalNetworkBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalNetworkBundle] {
            return inner.list()
        }
    }

    static func newCachedRegionalNetworkBundleStore(_ inner: MemoryRegionalNetworkBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalNetworkBundleStore {
        return CachedRegionalNetworkBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional network bundles. Empty fields match all.
    final class RegionalNetworkBundleQuery {
        var category: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minScore: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalNetworkBundle) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalNetworkBundle]) -> [RegionalNetworkBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalNetworkBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalNetworkBundles(_ store: any RegionalNetworkBundleStore, query: RegionalNetworkBundleQuery) -> [RegionalNetworkBundle] {
        return query.apply(store.list())
    }
}
