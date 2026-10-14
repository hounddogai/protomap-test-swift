import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy rollups by code.
    protocol ProxyRollupStore {
        func find(_ code: String) -> ProxyRollup?
        func save(_ item: ProxyRollup)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyRollupStore: ProxyRollupStore {
        var items: [String: ProxyRollup]
        var order: [String]

        init(items: [String: ProxyRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyRollup) {
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

        func list() -> [ProxyRollup] {
            var out: [ProxyRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyRollupStore() -> any ProxyRollupStore {
        return MemoryProxyRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyRollupStore: ProxyRollupStore {
        var inner: MemoryProxyRollupStore
        var cache: TTLCache<ProxyRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyRollupStore, cache: TTLCache<ProxyRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyRollup? {
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

        func save(_ item: ProxyRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyRollup] {
            return inner.list()
        }
    }

    static func newCachedProxyRollupStore(_ inner: MemoryProxyRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyRollupStore {
        return CachedProxyRollupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy rollups. Empty fields match all.
    final class ProxyRollupQuery {
        var facility: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minVersion: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyRollup) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyRollup]) -> [ProxyRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyRollups(_ store: any ProxyRollupStore, query: ProxyRollupQuery) -> [ProxyRollup] {
        return query.apply(store.list())
    }
}
