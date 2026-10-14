import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance bundles by code.
    protocol RemittanceBundleStore {
        func find(_ code: String) -> RemittanceBundle?
        func save(_ item: RemittanceBundle)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceBundleStore: RemittanceBundleStore {
        var items: [String: RemittanceBundle]
        var order: [String]

        init(items: [String: RemittanceBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceBundle) {
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

        func list() -> [RemittanceBundle] {
            var out: [RemittanceBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceBundleStore() -> any RemittanceBundleStore {
        return MemoryRemittanceBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceBundleStore: RemittanceBundleStore {
        var inner: MemoryRemittanceBundleStore
        var cache: TTLCache<RemittanceBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceBundleStore, cache: TTLCache<RemittanceBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceBundle? {
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

        func save(_ item: RemittanceBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceBundle] {
            return inner.list()
        }
    }

    static func newCachedRemittanceBundleStore(_ inner: MemoryRemittanceBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceBundleStore {
        return CachedRemittanceBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance bundles. Empty fields match all.
    final class RemittanceBundleQuery {
        var country: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceBundle) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceBundle]) -> [RemittanceBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceBundles(_ store: any RemittanceBundleStore, query: RemittanceBundleQuery) -> [RemittanceBundle] {
        return query.apply(store.list())
    }
}
