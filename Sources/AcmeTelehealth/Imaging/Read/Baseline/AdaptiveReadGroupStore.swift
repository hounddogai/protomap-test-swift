import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps adaptive read groups by code.
    protocol AdaptiveReadGroupStore {
        func find(_ code: String) -> AdaptiveReadGroup?
        func save(_ item: AdaptiveReadGroup)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveReadGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveReadGroupStore: AdaptiveReadGroupStore {
        var items: [String: AdaptiveReadGroup]
        var order: [String]

        init(items: [String: AdaptiveReadGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveReadGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveReadGroup) {
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

        func list() -> [AdaptiveReadGroup] {
            var out: [AdaptiveReadGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveReadGroupStore() -> any AdaptiveReadGroupStore {
        return MemoryAdaptiveReadGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveReadGroupStore: AdaptiveReadGroupStore {
        var inner: MemoryAdaptiveReadGroupStore
        var cache: TTLCache<AdaptiveReadGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveReadGroupStore, cache: TTLCache<AdaptiveReadGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveReadGroup? {
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

        func save(_ item: AdaptiveReadGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveReadGroup] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveReadGroupStore(_ inner: MemoryAdaptiveReadGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveReadGroupStore {
        return CachedAdaptiveReadGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive read groups. Empty fields match all.
    final class AdaptiveReadGroupQuery {
        var unit: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveReadGroup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveReadGroup]) -> [AdaptiveReadGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveReadGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveReadGroups(_ store: any AdaptiveReadGroupStore, query: AdaptiveReadGroupQuery) -> [AdaptiveReadGroup] {
        return query.apply(store.list())
    }
}
