import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy claims by code.
    protocol ProxyClaimStore {
        func find(_ code: String) -> ProxyClaim?
        func save(_ item: ProxyClaim)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyClaimStore: ProxyClaimStore {
        var items: [String: ProxyClaim]
        var order: [String]

        init(items: [String: ProxyClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyClaim) {
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

        func list() -> [ProxyClaim] {
            var out: [ProxyClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyClaimStore() -> any ProxyClaimStore {
        return MemoryProxyClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyClaimStore: ProxyClaimStore {
        var inner: MemoryProxyClaimStore
        var cache: TTLCache<ProxyClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyClaimStore, cache: TTLCache<ProxyClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyClaim? {
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

        func save(_ item: ProxyClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyClaim] {
            return inner.list()
        }
    }

    static func newCachedProxyClaimStore(_ inner: MemoryProxyClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyClaimStore {
        return CachedProxyClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy claims. Empty fields match all.
    final class ProxyClaimQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyClaim) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ProxyClaim]) -> [ProxyClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyClaims(_ store: any ProxyClaimStore, query: ProxyClaimQuery) -> [ProxyClaim] {
        return query.apply(store.list())
    }
}
