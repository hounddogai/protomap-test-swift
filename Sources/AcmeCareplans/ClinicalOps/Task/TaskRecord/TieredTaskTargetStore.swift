import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps tiered task targets by code.
    protocol TieredTaskTargetStore {
        func find(_ code: String) -> TieredTaskTarget?
        func save(_ item: TieredTaskTarget)
        func remove(_ code: String) -> Bool
        func list() -> [TieredTaskTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredTaskTargetStore: TieredTaskTargetStore {
        var items: [String: TieredTaskTarget]
        var order: [String]

        init(items: [String: TieredTaskTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredTaskTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredTaskTarget) {
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

        func list() -> [TieredTaskTarget] {
            var out: [TieredTaskTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredTaskTargetStore() -> any TieredTaskTargetStore {
        return MemoryTieredTaskTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredTaskTargetStore: TieredTaskTargetStore {
        var inner: MemoryTieredTaskTargetStore
        var cache: TTLCache<TieredTaskTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredTaskTargetStore, cache: TTLCache<TieredTaskTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredTaskTarget? {
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

        func save(_ item: TieredTaskTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredTaskTarget] {
            return inner.list()
        }
    }

    static func newCachedTieredTaskTargetStore(_ inner: MemoryTieredTaskTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredTaskTargetStore {
        return CachedTieredTaskTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered task targets. Empty fields match all.
    final class TieredTaskTargetQuery {
        var facility: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minBudget: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredTaskTarget) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [TieredTaskTarget]) -> [TieredTaskTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredTaskTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredTaskTargets(_ store: any TieredTaskTargetStore, query: TieredTaskTargetQuery) -> [TieredTaskTarget] {
        return query.apply(store.list())
    }
}
