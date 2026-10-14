import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered priority targets by code.
    protocol TieredPriorityTargetStore {
        func find(_ code: String) -> TieredPriorityTarget?
        func save(_ item: TieredPriorityTarget)
        func remove(_ code: String) -> Bool
        func list() -> [TieredPriorityTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredPriorityTargetStore: TieredPriorityTargetStore {
        var items: [String: TieredPriorityTarget]
        var order: [String]

        init(items: [String: TieredPriorityTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredPriorityTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredPriorityTarget) {
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

        func list() -> [TieredPriorityTarget] {
            var out: [TieredPriorityTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredPriorityTargetStore() -> any TieredPriorityTargetStore {
        return MemoryTieredPriorityTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredPriorityTargetStore: TieredPriorityTargetStore {
        var inner: MemoryTieredPriorityTargetStore
        var cache: TTLCache<TieredPriorityTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredPriorityTargetStore, cache: TTLCache<TieredPriorityTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredPriorityTarget? {
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

        func save(_ item: TieredPriorityTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredPriorityTarget] {
            return inner.list()
        }
    }

    static func newCachedTieredPriorityTargetStore(_ inner: MemoryTieredPriorityTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredPriorityTargetStore {
        return CachedTieredPriorityTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered priority targets. Empty fields match all.
    final class TieredPriorityTargetQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredPriorityTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredPriorityTarget]) -> [TieredPriorityTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredPriorityTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredPriorityTargets(_ store: any TieredPriorityTargetStore, query: TieredPriorityTargetQuery) -> [TieredPriorityTarget] {
        return query.apply(store.list())
    }
}
