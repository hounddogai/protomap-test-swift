import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal read groups by code.
    protocol SeasonalReadGroupStore {
        func find(_ code: String) -> SeasonalReadGroup?
        func save(_ item: SeasonalReadGroup)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalReadGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalReadGroupStore: SeasonalReadGroupStore {
        var items: [String: SeasonalReadGroup]
        var order: [String]

        init(items: [String: SeasonalReadGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalReadGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalReadGroup) {
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

        func list() -> [SeasonalReadGroup] {
            var out: [SeasonalReadGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalReadGroupStore() -> any SeasonalReadGroupStore {
        return MemorySeasonalReadGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalReadGroupStore: SeasonalReadGroupStore {
        var inner: MemorySeasonalReadGroupStore
        var cache: TTLCache<SeasonalReadGroup>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalReadGroupStore, cache: TTLCache<SeasonalReadGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalReadGroup? {
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

        func save(_ item: SeasonalReadGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalReadGroup] {
            return inner.list()
        }
    }

    static func newCachedSeasonalReadGroupStore(_ inner: MemorySeasonalReadGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalReadGroupStore {
        return CachedSeasonalReadGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal read groups. Empty fields match all.
    final class SeasonalReadGroupQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalReadGroup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalReadGroup]) -> [SeasonalReadGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalReadGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalReadGroups(_ store: any SeasonalReadGroupStore, query: SeasonalReadGroupQuery) -> [SeasonalReadGroup] {
        return query.apply(store.list())
    }
}
