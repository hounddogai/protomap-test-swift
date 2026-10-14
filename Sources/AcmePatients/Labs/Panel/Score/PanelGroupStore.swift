import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel groups by code.
    protocol PanelGroupStore {
        func find(_ code: String) -> PanelGroup?
        func save(_ item: PanelGroup)
        func remove(_ code: String) -> Bool
        func list() -> [PanelGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelGroupStore: PanelGroupStore {
        var items: [String: PanelGroup]
        var order: [String]

        init(items: [String: PanelGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelGroup) {
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

        func list() -> [PanelGroup] {
            var out: [PanelGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelGroupStore() -> any PanelGroupStore {
        return MemoryPanelGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelGroupStore: PanelGroupStore {
        var inner: MemoryPanelGroupStore
        var cache: TTLCache<PanelGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelGroupStore, cache: TTLCache<PanelGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelGroup? {
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

        func save(_ item: PanelGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelGroup] {
            return inner.list()
        }
    }

    static func newCachedPanelGroupStore(_ inner: MemoryPanelGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelGroupStore {
        return CachedPanelGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel groups. Empty fields match all.
    final class PanelGroupQuery {
        var category: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minLimit: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelGroup) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelGroup]) -> [PanelGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelGroups(_ store: any PanelGroupStore, query: PanelGroupQuery) -> [PanelGroup] {
        return query.apply(store.list())
    }
}
