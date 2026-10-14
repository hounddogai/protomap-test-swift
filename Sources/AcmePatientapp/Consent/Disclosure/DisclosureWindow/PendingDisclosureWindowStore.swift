import AcmePlatform
import Foundation

extension Consent {
    /// Keeps pending disclosure windows by code.
    protocol PendingDisclosureWindowStore {
        func find(_ code: String) -> PendingDisclosureWindow?
        func save(_ item: PendingDisclosureWindow)
        func remove(_ code: String) -> Bool
        func list() -> [PendingDisclosureWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingDisclosureWindowStore: PendingDisclosureWindowStore {
        var items: [String: PendingDisclosureWindow]
        var order: [String]

        init(items: [String: PendingDisclosureWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingDisclosureWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingDisclosureWindow) {
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

        func list() -> [PendingDisclosureWindow] {
            var out: [PendingDisclosureWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingDisclosureWindowStore() -> any PendingDisclosureWindowStore {
        return MemoryPendingDisclosureWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingDisclosureWindowStore: PendingDisclosureWindowStore {
        var inner: MemoryPendingDisclosureWindowStore
        var cache: TTLCache<PendingDisclosureWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingDisclosureWindowStore, cache: TTLCache<PendingDisclosureWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingDisclosureWindow? {
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

        func save(_ item: PendingDisclosureWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingDisclosureWindow] {
            return inner.list()
        }
    }

    static func newCachedPendingDisclosureWindowStore(_ inner: MemoryPendingDisclosureWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingDisclosureWindowStore {
        return CachedPendingDisclosureWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending disclosure windows. Empty fields match all.
    final class PendingDisclosureWindowQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingDisclosureWindow) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingDisclosureWindow]) -> [PendingDisclosureWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingDisclosureWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingDisclosureWindows(_ store: any PendingDisclosureWindowStore, query: PendingDisclosureWindowQuery) -> [PendingDisclosureWindow] {
        return query.apply(store.list())
    }
}
