import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional disclosure windows by code.
    protocol RegionalDisclosureWindowStore {
        func find(_ code: String) -> RegionalDisclosureWindow?
        func save(_ item: RegionalDisclosureWindow)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalDisclosureWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalDisclosureWindowStore: RegionalDisclosureWindowStore {
        var items: [String: RegionalDisclosureWindow]
        var order: [String]

        init(items: [String: RegionalDisclosureWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalDisclosureWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalDisclosureWindow) {
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

        func list() -> [RegionalDisclosureWindow] {
            var out: [RegionalDisclosureWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalDisclosureWindowStore() -> any RegionalDisclosureWindowStore {
        return MemoryRegionalDisclosureWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalDisclosureWindowStore: RegionalDisclosureWindowStore {
        var inner: MemoryRegionalDisclosureWindowStore
        var cache: TTLCache<RegionalDisclosureWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalDisclosureWindowStore, cache: TTLCache<RegionalDisclosureWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalDisclosureWindow? {
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

        func save(_ item: RegionalDisclosureWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalDisclosureWindow] {
            return inner.list()
        }
    }

    static func newCachedRegionalDisclosureWindowStore(_ inner: MemoryRegionalDisclosureWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalDisclosureWindowStore {
        return CachedRegionalDisclosureWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional disclosure windows. Empty fields match all.
    final class RegionalDisclosureWindowQuery {
        var channel: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minRate: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalDisclosureWindow) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalDisclosureWindow]) -> [RegionalDisclosureWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalDisclosureWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalDisclosureWindows(_ store: any RegionalDisclosureWindowStore, query: RegionalDisclosureWindowQuery) -> [RegionalDisclosureWindow] {
        return query.apply(store.list())
    }
}
