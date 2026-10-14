import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps regional interaction windows by code.
    protocol RegionalInteractionWindowStore {
        func find(_ code: String) -> RegionalInteractionWindow?
        func save(_ item: RegionalInteractionWindow)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalInteractionWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalInteractionWindowStore: RegionalInteractionWindowStore {
        var items: [String: RegionalInteractionWindow]
        var order: [String]

        init(items: [String: RegionalInteractionWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalInteractionWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalInteractionWindow) {
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

        func list() -> [RegionalInteractionWindow] {
            var out: [RegionalInteractionWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalInteractionWindowStore() -> any RegionalInteractionWindowStore {
        return MemoryRegionalInteractionWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalInteractionWindowStore: RegionalInteractionWindowStore {
        var inner: MemoryRegionalInteractionWindowStore
        var cache: TTLCache<RegionalInteractionWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalInteractionWindowStore, cache: TTLCache<RegionalInteractionWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalInteractionWindow? {
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

        func save(_ item: RegionalInteractionWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalInteractionWindow] {
            return inner.list()
        }
    }

    static func newCachedRegionalInteractionWindowStore(_ inner: MemoryRegionalInteractionWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalInteractionWindowStore {
        return CachedRegionalInteractionWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional interaction windows. Empty fields match all.
    final class RegionalInteractionWindowQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalInteractionWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalInteractionWindow]) -> [RegionalInteractionWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalInteractionWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalInteractionWindows(_ store: any RegionalInteractionWindowStore, query: RegionalInteractionWindowQuery) -> [RegionalInteractionWindow] {
        return query.apply(store.list())
    }
}
