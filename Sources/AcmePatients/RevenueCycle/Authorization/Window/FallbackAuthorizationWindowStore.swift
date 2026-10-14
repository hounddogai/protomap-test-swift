import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback authorization windows by code.
    protocol FallbackAuthorizationWindowStore {
        func find(_ code: String) -> FallbackAuthorizationWindow?
        func save(_ item: FallbackAuthorizationWindow)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackAuthorizationWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackAuthorizationWindowStore: FallbackAuthorizationWindowStore {
        var items: [String: FallbackAuthorizationWindow]
        var order: [String]

        init(items: [String: FallbackAuthorizationWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackAuthorizationWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackAuthorizationWindow) {
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

        func list() -> [FallbackAuthorizationWindow] {
            var out: [FallbackAuthorizationWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackAuthorizationWindowStore() -> any FallbackAuthorizationWindowStore {
        return MemoryFallbackAuthorizationWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackAuthorizationWindowStore: FallbackAuthorizationWindowStore {
        var inner: MemoryFallbackAuthorizationWindowStore
        var cache: TTLCache<FallbackAuthorizationWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackAuthorizationWindowStore, cache: TTLCache<FallbackAuthorizationWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackAuthorizationWindow? {
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

        func save(_ item: FallbackAuthorizationWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackAuthorizationWindow] {
            return inner.list()
        }
    }

    static func newCachedFallbackAuthorizationWindowStore(_ inner: MemoryFallbackAuthorizationWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackAuthorizationWindowStore {
        return CachedFallbackAuthorizationWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback authorization windows. Empty fields match all.
    final class FallbackAuthorizationWindowQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackAuthorizationWindow) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [FallbackAuthorizationWindow]) -> [FallbackAuthorizationWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackAuthorizationWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackAuthorizationWindows(_ store: any FallbackAuthorizationWindowStore, query: FallbackAuthorizationWindowQuery) -> [FallbackAuthorizationWindow] {
        return query.apply(store.list())
    }
}
