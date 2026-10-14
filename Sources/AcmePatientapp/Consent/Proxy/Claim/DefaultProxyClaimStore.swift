import AcmePlatform
import Foundation

extension Consent {
    /// Keeps default proxy claims by code.
    protocol DefaultProxyClaimStore {
        func find(_ code: String) -> DefaultProxyClaim?
        func save(_ item: DefaultProxyClaim)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultProxyClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultProxyClaimStore: DefaultProxyClaimStore {
        var items: [String: DefaultProxyClaim]
        var order: [String]

        init(items: [String: DefaultProxyClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultProxyClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultProxyClaim) {
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

        func list() -> [DefaultProxyClaim] {
            var out: [DefaultProxyClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultProxyClaimStore() -> any DefaultProxyClaimStore {
        return MemoryDefaultProxyClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultProxyClaimStore: DefaultProxyClaimStore {
        var inner: MemoryDefaultProxyClaimStore
        var cache: TTLCache<DefaultProxyClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultProxyClaimStore, cache: TTLCache<DefaultProxyClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultProxyClaim? {
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

        func save(_ item: DefaultProxyClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultProxyClaim] {
            return inner.list()
        }
    }

    static func newCachedDefaultProxyClaimStore(_ inner: MemoryDefaultProxyClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultProxyClaimStore {
        return CachedDefaultProxyClaimStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default proxy claims. Empty fields match all.
    final class DefaultProxyClaimQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultProxyClaim) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultProxyClaim]) -> [DefaultProxyClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultProxyClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultProxyClaims(_ store: any DefaultProxyClaimStore, query: DefaultProxyClaimQuery) -> [DefaultProxyClaim] {
        return query.apply(store.list())
    }
}
