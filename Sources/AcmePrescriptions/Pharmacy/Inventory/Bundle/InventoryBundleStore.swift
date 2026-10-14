import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory bundles by code.
    protocol InventoryBundleStore {
        func find(_ code: String) -> InventoryBundle?
        func save(_ item: InventoryBundle)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryBundleStore: InventoryBundleStore {
        var items: [String: InventoryBundle]
        var order: [String]

        init(items: [String: InventoryBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryBundle) {
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

        func list() -> [InventoryBundle] {
            var out: [InventoryBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryBundleStore() -> any InventoryBundleStore {
        return MemoryInventoryBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryBundleStore: InventoryBundleStore {
        var inner: MemoryInventoryBundleStore
        var cache: TTLCache<InventoryBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryBundleStore, cache: TTLCache<InventoryBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryBundle? {
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

        func save(_ item: InventoryBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryBundle] {
            return inner.list()
        }
    }

    static func newCachedInventoryBundleStore(_ inner: MemoryInventoryBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryBundleStore {
        return CachedInventoryBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory bundles. Empty fields match all.
    final class InventoryBundleQuery {
        var locale: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRevision: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryBundle) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryBundle]) -> [InventoryBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryBundles(_ store: any InventoryBundleStore, query: InventoryBundleQuery) -> [InventoryBundle] {
        return query.apply(store.list())
    }
}
