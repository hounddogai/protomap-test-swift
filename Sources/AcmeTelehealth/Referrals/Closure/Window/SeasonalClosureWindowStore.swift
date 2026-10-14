import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal closure windows by code.
    protocol SeasonalClosureWindowStore {
        func find(_ code: String) -> SeasonalClosureWindow?
        func save(_ item: SeasonalClosureWindow)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalClosureWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalClosureWindowStore: SeasonalClosureWindowStore {
        var items: [String: SeasonalClosureWindow]
        var order: [String]

        init(items: [String: SeasonalClosureWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalClosureWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalClosureWindow) {
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

        func list() -> [SeasonalClosureWindow] {
            var out: [SeasonalClosureWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalClosureWindowStore() -> any SeasonalClosureWindowStore {
        return MemorySeasonalClosureWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalClosureWindowStore: SeasonalClosureWindowStore {
        var inner: MemorySeasonalClosureWindowStore
        var cache: TTLCache<SeasonalClosureWindow>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalClosureWindowStore, cache: TTLCache<SeasonalClosureWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalClosureWindow? {
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

        func save(_ item: SeasonalClosureWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalClosureWindow] {
            return inner.list()
        }
    }

    static func newCachedSeasonalClosureWindowStore(_ inner: MemorySeasonalClosureWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalClosureWindowStore {
        return CachedSeasonalClosureWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal closure windows. Empty fields match all.
    final class SeasonalClosureWindowQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalClosureWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [SeasonalClosureWindow]) -> [SeasonalClosureWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalClosureWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalClosureWindows(_ store: any SeasonalClosureWindowStore, query: SeasonalClosureWindowQuery) -> [SeasonalClosureWindow] {
        return query.apply(store.list())
    }
}
