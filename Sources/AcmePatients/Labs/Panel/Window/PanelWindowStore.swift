import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel windows by code.
    protocol PanelWindowStore {
        func find(_ code: String) -> PanelWindow?
        func save(_ item: PanelWindow)
        func remove(_ code: String) -> Bool
        func list() -> [PanelWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelWindowStore: PanelWindowStore {
        var items: [String: PanelWindow]
        var order: [String]

        init(items: [String: PanelWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelWindow) {
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

        func list() -> [PanelWindow] {
            var out: [PanelWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelWindowStore() -> any PanelWindowStore {
        return MemoryPanelWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelWindowStore: PanelWindowStore {
        var inner: MemoryPanelWindowStore
        var cache: TTLCache<PanelWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelWindowStore, cache: TTLCache<PanelWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelWindow? {
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

        func save(_ item: PanelWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelWindow] {
            return inner.list()
        }
    }

    static func newCachedPanelWindowStore(_ inner: MemoryPanelWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelWindowStore {
        return CachedPanelWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel windows. Empty fields match all.
    final class PanelWindowQuery {
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

        func matches(_ item: PanelWindow) -> Bool {
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

        func apply(_ items: [PanelWindow]) -> [PanelWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelWindows(_ store: any PanelWindowStore, query: PanelWindowQuery) -> [PanelWindow] {
        return query.apply(store.list())
    }
}
