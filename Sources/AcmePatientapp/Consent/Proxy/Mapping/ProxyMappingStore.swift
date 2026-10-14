import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy mappings by code.
    protocol ProxyMappingStore {
        func find(_ code: String) -> ProxyMapping?
        func save(_ item: ProxyMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyMappingStore: ProxyMappingStore {
        var items: [String: ProxyMapping]
        var order: [String]

        init(items: [String: ProxyMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyMapping) {
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

        func list() -> [ProxyMapping] {
            var out: [ProxyMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyMappingStore() -> any ProxyMappingStore {
        return MemoryProxyMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyMappingStore: ProxyMappingStore {
        var inner: MemoryProxyMappingStore
        var cache: TTLCache<ProxyMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyMappingStore, cache: TTLCache<ProxyMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyMapping? {
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

        func save(_ item: ProxyMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyMapping] {
            return inner.list()
        }
    }

    static func newCachedProxyMappingStore(_ inner: MemoryProxyMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyMappingStore {
        return CachedProxyMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy mappings. Empty fields match all.
    final class ProxyMappingQuery {
        var title: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minWeight: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyMapping]) -> [ProxyMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyMappings(_ store: any ProxyMappingStore, query: ProxyMappingQuery) -> [ProxyMapping] {
        return query.apply(store.list())
    }
}
