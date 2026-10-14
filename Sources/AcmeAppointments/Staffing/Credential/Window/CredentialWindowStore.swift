import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential windows by code.
    protocol CredentialWindowStore {
        func find(_ code: String) -> CredentialWindow?
        func save(_ item: CredentialWindow)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialWindowStore: CredentialWindowStore {
        var items: [String: CredentialWindow]
        var order: [String]

        init(items: [String: CredentialWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialWindow) {
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

        func list() -> [CredentialWindow] {
            var out: [CredentialWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialWindowStore() -> any CredentialWindowStore {
        return MemoryCredentialWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialWindowStore: CredentialWindowStore {
        var inner: MemoryCredentialWindowStore
        var cache: TTLCache<CredentialWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialWindowStore, cache: TTLCache<CredentialWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialWindow? {
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

        func save(_ item: CredentialWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialWindow] {
            return inner.list()
        }
    }

    static func newCachedCredentialWindowStore(_ inner: MemoryCredentialWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialWindowStore {
        return CachedCredentialWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential windows. Empty fields match all.
    final class CredentialWindowQuery {
        var segment: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialWindow) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [CredentialWindow]) -> [CredentialWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialWindows(_ store: any CredentialWindowStore, query: CredentialWindowQuery) -> [CredentialWindow] {
        return query.apply(store.list())
    }
}
