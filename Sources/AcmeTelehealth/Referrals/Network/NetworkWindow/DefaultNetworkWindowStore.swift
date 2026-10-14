import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps default network windows by code.
    protocol DefaultNetworkWindowStore {
        func find(_ code: String) -> DefaultNetworkWindow?
        func save(_ item: DefaultNetworkWindow)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultNetworkWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultNetworkWindowStore: DefaultNetworkWindowStore {
        var items: [String: DefaultNetworkWindow]
        var order: [String]

        init(items: [String: DefaultNetworkWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultNetworkWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultNetworkWindow) {
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

        func list() -> [DefaultNetworkWindow] {
            var out: [DefaultNetworkWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultNetworkWindowStore() -> any DefaultNetworkWindowStore {
        return MemoryDefaultNetworkWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultNetworkWindowStore: DefaultNetworkWindowStore {
        var inner: MemoryDefaultNetworkWindowStore
        var cache: TTLCache<DefaultNetworkWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultNetworkWindowStore, cache: TTLCache<DefaultNetworkWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultNetworkWindow? {
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

        func save(_ item: DefaultNetworkWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultNetworkWindow] {
            return inner.list()
        }
    }

    static func newCachedDefaultNetworkWindowStore(_ inner: MemoryDefaultNetworkWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultNetworkWindowStore {
        return CachedDefaultNetworkWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default network windows. Empty fields match all.
    final class DefaultNetworkWindowQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultNetworkWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [DefaultNetworkWindow]) -> [DefaultNetworkWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultNetworkWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultNetworkWindows(_ store: any DefaultNetworkWindowStore, query: DefaultNetworkWindowQuery) -> [DefaultNetworkWindow] {
        return query.apply(store.list())
    }
}
