import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure windows by code.
    protocol DisclosureWindowStore {
        func find(_ code: String) -> DisclosureWindow?
        func save(_ item: DisclosureWindow)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureWindowStore: DisclosureWindowStore {
        var items: [String: DisclosureWindow]
        var order: [String]

        init(items: [String: DisclosureWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureWindow) {
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

        func list() -> [DisclosureWindow] {
            var out: [DisclosureWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureWindowStore() -> any DisclosureWindowStore {
        return MemoryDisclosureWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureWindowStore: DisclosureWindowStore {
        var inner: MemoryDisclosureWindowStore
        var cache: TTLCache<DisclosureWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureWindowStore, cache: TTLCache<DisclosureWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureWindow? {
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

        func save(_ item: DisclosureWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureWindow] {
            return inner.list()
        }
    }

    static func newCachedDisclosureWindowStore(_ inner: MemoryDisclosureWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureWindowStore {
        return CachedDisclosureWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure windows. Empty fields match all.
    final class DisclosureWindowQuery {
        var locale: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureWindow) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureWindow]) -> [DisclosureWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureWindows(_ store: any DisclosureWindowStore, query: DisclosureWindowQuery) -> [DisclosureWindow] {
        return query.apply(store.list())
    }
}
