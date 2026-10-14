import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient proxy claims by code.
    protocol LenientProxyClaimStore {
        func find(_ code: String) -> LenientProxyClaim?
        func save(_ item: LenientProxyClaim)
        func remove(_ code: String) -> Bool
        func list() -> [LenientProxyClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientProxyClaimStore: LenientProxyClaimStore {
        var items: [String: LenientProxyClaim]
        var order: [String]

        init(items: [String: LenientProxyClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientProxyClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientProxyClaim) {
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

        func list() -> [LenientProxyClaim] {
            var out: [LenientProxyClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientProxyClaimStore() -> any LenientProxyClaimStore {
        return MemoryLenientProxyClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientProxyClaimStore: LenientProxyClaimStore {
        var inner: MemoryLenientProxyClaimStore
        var cache: TTLCache<LenientProxyClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientProxyClaimStore, cache: TTLCache<LenientProxyClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientProxyClaim? {
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

        func save(_ item: LenientProxyClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientProxyClaim] {
            return inner.list()
        }
    }

    static func newCachedLenientProxyClaimStore(_ inner: MemoryLenientProxyClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientProxyClaimStore {
        return CachedLenientProxyClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient proxy claims. Empty fields match all.
    final class LenientProxyClaimQuery {
        var ward: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientProxyClaim) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientProxyClaim]) -> [LenientProxyClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientProxyClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientProxyClaims(_ store: any LenientProxyClaimStore, query: LenientProxyClaimQuery) -> [LenientProxyClaim] {
        return query.apply(store.list())
    }
}
