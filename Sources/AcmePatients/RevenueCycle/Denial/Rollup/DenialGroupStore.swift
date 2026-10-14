import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial groups by code.
    protocol DenialGroupStore {
        func find(_ code: String) -> DenialGroup?
        func save(_ item: DenialGroup)
        func remove(_ code: String) -> Bool
        func list() -> [DenialGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialGroupStore: DenialGroupStore {
        var items: [String: DenialGroup]
        var order: [String]

        init(items: [String: DenialGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialGroup) {
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

        func list() -> [DenialGroup] {
            var out: [DenialGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialGroupStore() -> any DenialGroupStore {
        return MemoryDenialGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialGroupStore: DenialGroupStore {
        var inner: MemoryDenialGroupStore
        var cache: TTLCache<DenialGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialGroupStore, cache: TTLCache<DenialGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialGroup? {
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

        func save(_ item: DenialGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialGroup] {
            return inner.list()
        }
    }

    static func newCachedDenialGroupStore(_ inner: MemoryDenialGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialGroupStore {
        return CachedDenialGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial groups. Empty fields match all.
    final class DenialGroupQuery {
        var title: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCost: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialGroup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialGroup]) -> [DenialGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialGroups(_ store: any DenialGroupStore, query: DenialGroupQuery) -> [DenialGroup] {
        return query.apply(store.list())
    }
}
