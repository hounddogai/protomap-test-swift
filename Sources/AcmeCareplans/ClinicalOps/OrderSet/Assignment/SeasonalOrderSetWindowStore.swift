import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps seasonal order set windows by code.
    protocol SeasonalOrderSetWindowStore {
        func find(_ code: String) -> SeasonalOrderSetWindow?
        func save(_ item: SeasonalOrderSetWindow)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalOrderSetWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalOrderSetWindowStore: SeasonalOrderSetWindowStore {
        var items: [String: SeasonalOrderSetWindow]
        var order: [String]

        init(items: [String: SeasonalOrderSetWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalOrderSetWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalOrderSetWindow) {
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

        func list() -> [SeasonalOrderSetWindow] {
            var out: [SeasonalOrderSetWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalOrderSetWindowStore() -> any SeasonalOrderSetWindowStore {
        return MemorySeasonalOrderSetWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalOrderSetWindowStore: SeasonalOrderSetWindowStore {
        var inner: MemorySeasonalOrderSetWindowStore
        var cache: TTLCache<SeasonalOrderSetWindow>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalOrderSetWindowStore, cache: TTLCache<SeasonalOrderSetWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalOrderSetWindow? {
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

        func save(_ item: SeasonalOrderSetWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalOrderSetWindow] {
            return inner.list()
        }
    }

    static func newCachedSeasonalOrderSetWindowStore(_ inner: MemorySeasonalOrderSetWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalOrderSetWindowStore {
        return CachedSeasonalOrderSetWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal order set windows. Empty fields match all.
    final class SeasonalOrderSetWindowQuery {
        var name: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalOrderSetWindow) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [SeasonalOrderSetWindow]) -> [SeasonalOrderSetWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalOrderSetWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalOrderSetWindows(_ store: any SeasonalOrderSetWindowStore, query: SeasonalOrderSetWindowQuery) -> [SeasonalOrderSetWindow] {
        return query.apply(store.list())
    }
}
