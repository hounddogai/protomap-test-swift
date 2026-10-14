import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy overrides by code.
    protocol ProxyOverrideStore {
        func find(_ code: String) -> ProxyOverride?
        func save(_ item: ProxyOverride)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyOverrideStore: ProxyOverrideStore {
        var items: [String: ProxyOverride]
        var order: [String]

        init(items: [String: ProxyOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyOverride) {
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

        func list() -> [ProxyOverride] {
            var out: [ProxyOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyOverrideStore() -> any ProxyOverrideStore {
        return MemoryProxyOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyOverrideStore: ProxyOverrideStore {
        var inner: MemoryProxyOverrideStore
        var cache: TTLCache<ProxyOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyOverrideStore, cache: TTLCache<ProxyOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyOverride? {
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

        func save(_ item: ProxyOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyOverride] {
            return inner.list()
        }
    }

    static func newCachedProxyOverrideStore(_ inner: MemoryProxyOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyOverrideStore {
        return CachedProxyOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy overrides. Empty fields match all.
    final class ProxyOverrideQuery {
        var channel: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyOverride) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyOverride]) -> [ProxyOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyOverrides(_ store: any ProxyOverrideStore, query: ProxyOverrideQuery) -> [ProxyOverride] {
        return query.apply(store.list())
    }
}
