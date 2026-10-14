import AcmePlatform
import Foundation

extension Labs {
    /// Keeps scheduled panel groups by code.
    protocol ScheduledPanelGroupStore {
        func find(_ code: String) -> ScheduledPanelGroup?
        func save(_ item: ScheduledPanelGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledPanelGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledPanelGroupStore: ScheduledPanelGroupStore {
        var items: [String: ScheduledPanelGroup]
        var order: [String]

        init(items: [String: ScheduledPanelGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledPanelGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledPanelGroup) {
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

        func list() -> [ScheduledPanelGroup] {
            var out: [ScheduledPanelGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledPanelGroupStore() -> any ScheduledPanelGroupStore {
        return MemoryScheduledPanelGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledPanelGroupStore: ScheduledPanelGroupStore {
        var inner: MemoryScheduledPanelGroupStore
        var cache: TTLCache<ScheduledPanelGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledPanelGroupStore, cache: TTLCache<ScheduledPanelGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledPanelGroup? {
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

        func save(_ item: ScheduledPanelGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledPanelGroup] {
            return inner.list()
        }
    }

    static func newCachedScheduledPanelGroupStore(_ inner: MemoryScheduledPanelGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledPanelGroupStore {
        return CachedScheduledPanelGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled panel groups. Empty fields match all.
    final class ScheduledPanelGroupQuery {
        var ward: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCost: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledPanelGroup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ScheduledPanelGroup]) -> [ScheduledPanelGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledPanelGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledPanelGroups(_ store: any ScheduledPanelGroupStore, query: ScheduledPanelGroupQuery) -> [ScheduledPanelGroup] {
        return query.apply(store.list())
    }
}
