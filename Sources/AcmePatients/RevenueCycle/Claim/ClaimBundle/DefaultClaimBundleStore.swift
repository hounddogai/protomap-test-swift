import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps default claim bundles by code.
    protocol DefaultClaimBundleStore {
        func find(_ code: String) -> DefaultClaimBundle?
        func save(_ item: DefaultClaimBundle)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultClaimBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultClaimBundleStore: DefaultClaimBundleStore {
        var items: [String: DefaultClaimBundle]
        var order: [String]

        init(items: [String: DefaultClaimBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultClaimBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultClaimBundle) {
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

        func list() -> [DefaultClaimBundle] {
            var out: [DefaultClaimBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultClaimBundleStore() -> any DefaultClaimBundleStore {
        return MemoryDefaultClaimBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultClaimBundleStore: DefaultClaimBundleStore {
        var inner: MemoryDefaultClaimBundleStore
        var cache: TTLCache<DefaultClaimBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultClaimBundleStore, cache: TTLCache<DefaultClaimBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultClaimBundle? {
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

        func save(_ item: DefaultClaimBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultClaimBundle] {
            return inner.list()
        }
    }

    static func newCachedDefaultClaimBundleStore(_ inner: MemoryDefaultClaimBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultClaimBundleStore {
        return CachedDefaultClaimBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default claim bundles. Empty fields match all.
    final class DefaultClaimBundleQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultClaimBundle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultClaimBundle]) -> [DefaultClaimBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultClaimBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultClaimBundles(_ store: any DefaultClaimBundleStore, query: DefaultClaimBundleQuery) -> [DefaultClaimBundle] {
        return query.apply(store.list())
    }
}
