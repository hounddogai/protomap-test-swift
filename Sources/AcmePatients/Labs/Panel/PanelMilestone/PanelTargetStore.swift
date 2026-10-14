import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel targets by code.
    protocol PanelTargetStore {
        func find(_ code: String) -> PanelTarget?
        func save(_ item: PanelTarget)
        func remove(_ code: String) -> Bool
        func list() -> [PanelTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelTargetStore: PanelTargetStore {
        var items: [String: PanelTarget]
        var order: [String]

        init(items: [String: PanelTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelTarget) {
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

        func list() -> [PanelTarget] {
            var out: [PanelTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelTargetStore() -> any PanelTargetStore {
        return MemoryPanelTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelTargetStore: PanelTargetStore {
        var inner: MemoryPanelTargetStore
        var cache: TTLCache<PanelTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelTargetStore, cache: TTLCache<PanelTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelTarget? {
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

        func save(_ item: PanelTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelTarget] {
            return inner.list()
        }
    }

    static func newCachedPanelTargetStore(_ inner: MemoryPanelTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelTargetStore {
        return CachedPanelTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel targets. Empty fields match all.
    final class PanelTargetQuery {
        var title: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minBudget: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelTarget) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelTarget]) -> [PanelTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelTargets(_ store: any PanelTargetStore, query: PanelTargetQuery) -> [PanelTarget] {
        return query.apply(store.list())
    }
}
