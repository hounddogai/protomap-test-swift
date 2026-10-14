import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global credential windows by code.
    protocol GlobalCredentialWindowStore {
        func find(_ code: String) -> GlobalCredentialWindow?
        func save(_ item: GlobalCredentialWindow)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCredentialWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCredentialWindowStore: GlobalCredentialWindowStore {
        var items: [String: GlobalCredentialWindow]
        var order: [String]

        init(items: [String: GlobalCredentialWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCredentialWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCredentialWindow) {
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

        func list() -> [GlobalCredentialWindow] {
            var out: [GlobalCredentialWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCredentialWindowStore() -> any GlobalCredentialWindowStore {
        return MemoryGlobalCredentialWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCredentialWindowStore: GlobalCredentialWindowStore {
        var inner: MemoryGlobalCredentialWindowStore
        var cache: TTLCache<GlobalCredentialWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCredentialWindowStore, cache: TTLCache<GlobalCredentialWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCredentialWindow? {
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

        func save(_ item: GlobalCredentialWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCredentialWindow] {
            return inner.list()
        }
    }

    static func newCachedGlobalCredentialWindowStore(_ inner: MemoryGlobalCredentialWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCredentialWindowStore {
        return CachedGlobalCredentialWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global credential windows. Empty fields match all.
    final class GlobalCredentialWindowQuery {
        var country: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCredentialWindow) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalCredentialWindow]) -> [GlobalCredentialWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCredentialWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCredentialWindows(_ store: any GlobalCredentialWindowStore, query: GlobalCredentialWindowQuery) -> [GlobalCredentialWindow] {
        return query.apply(store.list())
    }
}
