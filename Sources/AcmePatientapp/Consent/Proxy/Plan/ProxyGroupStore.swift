import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy groups by code.
    protocol ProxyGroupStore {
        func find(_ code: String) -> ProxyGroup?
        func save(_ item: ProxyGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyGroupStore: ProxyGroupStore {
        var items: [String: ProxyGroup]
        var order: [String]

        init(items: [String: ProxyGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyGroup) {
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

        func list() -> [ProxyGroup] {
            var out: [ProxyGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyGroupStore() -> any ProxyGroupStore {
        return MemoryProxyGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyGroupStore: ProxyGroupStore {
        var inner: MemoryProxyGroupStore
        var cache: TTLCache<ProxyGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyGroupStore, cache: TTLCache<ProxyGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyGroup? {
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

        func save(_ item: ProxyGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyGroup] {
            return inner.list()
        }
    }

    static func newCachedProxyGroupStore(_ inner: MemoryProxyGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyGroupStore {
        return CachedProxyGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy groups. Empty fields match all.
    final class ProxyGroupQuery {
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

        func matches(_ item: ProxyGroup) -> Bool {
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

        func apply(_ items: [ProxyGroup]) -> [ProxyGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyGroups(_ store: any ProxyGroupStore, query: ProxyGroupQuery) -> [ProxyGroup] {
        return query.apply(store.list())
    }
}
