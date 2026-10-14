import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal panel windows by code.
    protocol SeasonalPanelWindowStore {
        func find(_ code: String) -> SeasonalPanelWindow?
        func save(_ item: SeasonalPanelWindow)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalPanelWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalPanelWindowStore: SeasonalPanelWindowStore {
        var items: [String: SeasonalPanelWindow]
        var order: [String]

        init(items: [String: SeasonalPanelWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalPanelWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalPanelWindow) {
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

        func list() -> [SeasonalPanelWindow] {
            var out: [SeasonalPanelWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalPanelWindowStore() -> any SeasonalPanelWindowStore {
        return MemorySeasonalPanelWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalPanelWindowStore: SeasonalPanelWindowStore {
        var inner: MemorySeasonalPanelWindowStore
        var cache: TTLCache<SeasonalPanelWindow>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalPanelWindowStore, cache: TTLCache<SeasonalPanelWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalPanelWindow? {
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

        func save(_ item: SeasonalPanelWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalPanelWindow] {
            return inner.list()
        }
    }

    static func newCachedSeasonalPanelWindowStore(_ inner: MemorySeasonalPanelWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalPanelWindowStore {
        return CachedSeasonalPanelWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal panel windows. Empty fields match all.
    final class SeasonalPanelWindowQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalPanelWindow) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalPanelWindow]) -> [SeasonalPanelWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalPanelWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalPanelWindows(_ store: any SeasonalPanelWindowStore, query: SeasonalPanelWindowQuery) -> [SeasonalPanelWindow] {
        return query.apply(store.list())
    }
}
