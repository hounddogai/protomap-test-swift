import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy windows by code.
    protocol ProxyWindowStore {
        func find(_ code: String) -> ProxyWindow?
        func save(_ item: ProxyWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyWindowStore: ProxyWindowStore {
        var items: [String: ProxyWindow]
        var order: [String]

        init(items: [String: ProxyWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyWindow) {
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

        func list() -> [ProxyWindow] {
            var out: [ProxyWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyWindowStore() -> any ProxyWindowStore {
        return MemoryProxyWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyWindowStore: ProxyWindowStore {
        var inner: MemoryProxyWindowStore
        var cache: TTLCache<ProxyWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyWindowStore, cache: TTLCache<ProxyWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyWindow? {
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

        func save(_ item: ProxyWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyWindow] {
            return inner.list()
        }
    }

    static func newCachedProxyWindowStore(_ inner: MemoryProxyWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyWindowStore {
        return CachedProxyWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy windows. Empty fields match all.
    final class ProxyWindowQuery {
        var facility: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minLimit: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyWindow) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyWindow]) -> [ProxyWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyWindows(_ store: any ProxyWindowStore, query: ProxyWindowQuery) -> [ProxyWindow] {
        return query.apply(store.list())
    }
}
