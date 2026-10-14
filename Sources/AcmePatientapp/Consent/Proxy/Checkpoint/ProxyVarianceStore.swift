import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy variances by code.
    protocol ProxyVarianceStore {
        func find(_ code: String) -> ProxyVariance?
        func save(_ item: ProxyVariance)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyVarianceStore: ProxyVarianceStore {
        var items: [String: ProxyVariance]
        var order: [String]

        init(items: [String: ProxyVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyVariance) {
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

        func list() -> [ProxyVariance] {
            var out: [ProxyVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyVarianceStore() -> any ProxyVarianceStore {
        return MemoryProxyVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyVarianceStore: ProxyVarianceStore {
        var inner: MemoryProxyVarianceStore
        var cache: TTLCache<ProxyVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyVarianceStore, cache: TTLCache<ProxyVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyVariance? {
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

        func save(_ item: ProxyVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyVariance] {
            return inner.list()
        }
    }

    static func newCachedProxyVarianceStore(_ inner: MemoryProxyVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyVarianceStore {
        return CachedProxyVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy variances. Empty fields match all.
    final class ProxyVarianceQuery {
        var channel: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRevision: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyVariance) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ProxyVariance]) -> [ProxyVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyVariances(_ store: any ProxyVarianceStore, query: ProxyVarianceQuery) -> [ProxyVariance] {
        return query.apply(store.list())
    }
}
