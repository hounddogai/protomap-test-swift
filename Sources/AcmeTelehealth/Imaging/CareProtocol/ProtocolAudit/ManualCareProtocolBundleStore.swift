import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual care protocol bundles by code.
    protocol ManualCareProtocolBundleStore {
        func find(_ code: String) -> ManualCareProtocolBundle?
        func save(_ item: ManualCareProtocolBundle)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCareProtocolBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCareProtocolBundleStore: ManualCareProtocolBundleStore {
        var items: [String: ManualCareProtocolBundle]
        var order: [String]

        init(items: [String: ManualCareProtocolBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCareProtocolBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCareProtocolBundle) {
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

        func list() -> [ManualCareProtocolBundle] {
            var out: [ManualCareProtocolBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCareProtocolBundleStore() -> any ManualCareProtocolBundleStore {
        return MemoryManualCareProtocolBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCareProtocolBundleStore: ManualCareProtocolBundleStore {
        var inner: MemoryManualCareProtocolBundleStore
        var cache: TTLCache<ManualCareProtocolBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCareProtocolBundleStore, cache: TTLCache<ManualCareProtocolBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCareProtocolBundle? {
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

        func save(_ item: ManualCareProtocolBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCareProtocolBundle] {
            return inner.list()
        }
    }

    static func newCachedManualCareProtocolBundleStore(_ inner: MemoryManualCareProtocolBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCareProtocolBundleStore {
        return CachedManualCareProtocolBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual care protocol bundles. Empty fields match all.
    final class ManualCareProtocolBundleQuery {
        var country: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCareProtocolBundle) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [ManualCareProtocolBundle]) -> [ManualCareProtocolBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCareProtocolBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCareProtocolBundles(_ store: any ManualCareProtocolBundleStore, query: ManualCareProtocolBundleQuery) -> [ManualCareProtocolBundle] {
        return query.apply(store.list())
    }
}
