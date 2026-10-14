import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback panel groups by code.
    protocol FallbackPanelGroupStore {
        func find(_ code: String) -> FallbackPanelGroup?
        func save(_ item: FallbackPanelGroup)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackPanelGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackPanelGroupStore: FallbackPanelGroupStore {
        var items: [String: FallbackPanelGroup]
        var order: [String]

        init(items: [String: FallbackPanelGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackPanelGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackPanelGroup) {
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

        func list() -> [FallbackPanelGroup] {
            var out: [FallbackPanelGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackPanelGroupStore() -> any FallbackPanelGroupStore {
        return MemoryFallbackPanelGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackPanelGroupStore: FallbackPanelGroupStore {
        var inner: MemoryFallbackPanelGroupStore
        var cache: TTLCache<FallbackPanelGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackPanelGroupStore, cache: TTLCache<FallbackPanelGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackPanelGroup? {
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

        func save(_ item: FallbackPanelGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackPanelGroup] {
            return inner.list()
        }
    }

    static func newCachedFallbackPanelGroupStore(_ inner: MemoryFallbackPanelGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackPanelGroupStore {
        return CachedFallbackPanelGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback panel groups. Empty fields match all.
    final class FallbackPanelGroupQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackPanelGroup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackPanelGroup]) -> [FallbackPanelGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackPanelGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackPanelGroups(_ store: any FallbackPanelGroupStore, query: FallbackPanelGroupQuery) -> [FallbackPanelGroup] {
        return query.apply(store.list())
    }
}
