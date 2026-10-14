import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy profiles by code.
    protocol ProxyProfileStore {
        func find(_ code: String) -> ProxyProfile?
        func save(_ item: ProxyProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyProfileStore: ProxyProfileStore {
        var items: [String: ProxyProfile]
        var order: [String]

        init(items: [String: ProxyProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyProfile) {
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

        func list() -> [ProxyProfile] {
            var out: [ProxyProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyProfileStore() -> any ProxyProfileStore {
        return MemoryProxyProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyProfileStore: ProxyProfileStore {
        var inner: MemoryProxyProfileStore
        var cache: TTLCache<ProxyProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyProfileStore, cache: TTLCache<ProxyProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyProfile? {
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

        func save(_ item: ProxyProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyProfile] {
            return inner.list()
        }
    }

    static func newCachedProxyProfileStore(_ inner: MemoryProxyProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyProfileStore {
        return CachedProxyProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy profiles. Empty fields match all.
    final class ProxyProfileQuery {
        var country: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRatio: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyProfile) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyProfile]) -> [ProxyProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyProfiles(_ store: any ProxyProfileStore, query: ProxyProfileQuery) -> [ProxyProfile] {
        return query.apply(store.list())
    }
}
