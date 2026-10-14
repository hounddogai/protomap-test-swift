import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual priority targets by code.
    protocol ManualPriorityTargetStore {
        func find(_ code: String) -> ManualPriorityTarget?
        func save(_ item: ManualPriorityTarget)
        func remove(_ code: String) -> Bool
        func list() -> [ManualPriorityTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualPriorityTargetStore: ManualPriorityTargetStore {
        var items: [String: ManualPriorityTarget]
        var order: [String]

        init(items: [String: ManualPriorityTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualPriorityTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualPriorityTarget) {
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

        func list() -> [ManualPriorityTarget] {
            var out: [ManualPriorityTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualPriorityTargetStore() -> any ManualPriorityTargetStore {
        return MemoryManualPriorityTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualPriorityTargetStore: ManualPriorityTargetStore {
        var inner: MemoryManualPriorityTargetStore
        var cache: TTLCache<ManualPriorityTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualPriorityTargetStore, cache: TTLCache<ManualPriorityTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualPriorityTarget? {
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

        func save(_ item: ManualPriorityTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualPriorityTarget] {
            return inner.list()
        }
    }

    static func newCachedManualPriorityTargetStore(_ inner: MemoryManualPriorityTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualPriorityTargetStore {
        return CachedManualPriorityTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual priority targets. Empty fields match all.
    final class ManualPriorityTargetQuery {
        var country: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minPriority: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualPriorityTarget) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualPriorityTarget]) -> [ManualPriorityTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualPriorityTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualPriorityTargets(_ store: any ManualPriorityTargetStore, query: ManualPriorityTargetQuery) -> [ManualPriorityTarget] {
        return query.apply(store.list())
    }
}
