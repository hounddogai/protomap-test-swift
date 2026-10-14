import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered network bundles by code.
    protocol TieredNetworkBundleStore {
        func find(_ code: String) -> TieredNetworkBundle?
        func save(_ item: TieredNetworkBundle)
        func remove(_ code: String) -> Bool
        func list() -> [TieredNetworkBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredNetworkBundleStore: TieredNetworkBundleStore {
        var items: [String: TieredNetworkBundle]
        var order: [String]

        init(items: [String: TieredNetworkBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredNetworkBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredNetworkBundle) {
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

        func list() -> [TieredNetworkBundle] {
            var out: [TieredNetworkBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredNetworkBundleStore() -> any TieredNetworkBundleStore {
        return MemoryTieredNetworkBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredNetworkBundleStore: TieredNetworkBundleStore {
        var inner: MemoryTieredNetworkBundleStore
        var cache: TTLCache<TieredNetworkBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredNetworkBundleStore, cache: TTLCache<TieredNetworkBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredNetworkBundle? {
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

        func save(_ item: TieredNetworkBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredNetworkBundle] {
            return inner.list()
        }
    }

    static func newCachedTieredNetworkBundleStore(_ inner: MemoryTieredNetworkBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredNetworkBundleStore {
        return CachedTieredNetworkBundleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered network bundles. Empty fields match all.
    final class TieredNetworkBundleQuery {
        var source: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minAmount: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredNetworkBundle) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredNetworkBundle]) -> [TieredNetworkBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredNetworkBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredNetworkBundles(_ store: any TieredNetworkBundleStore, query: TieredNetworkBundleQuery) -> [TieredNetworkBundle] {
        return query.apply(store.list())
    }
}
