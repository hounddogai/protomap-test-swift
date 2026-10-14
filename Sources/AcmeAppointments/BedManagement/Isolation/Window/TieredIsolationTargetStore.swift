import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps tiered isolation targets by code.
    protocol TieredIsolationTargetStore {
        func find(_ code: String) -> TieredIsolationTarget?
        func save(_ item: TieredIsolationTarget)
        func remove(_ code: String) -> Bool
        func list() -> [TieredIsolationTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredIsolationTargetStore: TieredIsolationTargetStore {
        var items: [String: TieredIsolationTarget]
        var order: [String]

        init(items: [String: TieredIsolationTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredIsolationTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredIsolationTarget) {
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

        func list() -> [TieredIsolationTarget] {
            var out: [TieredIsolationTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredIsolationTargetStore() -> any TieredIsolationTargetStore {
        return MemoryTieredIsolationTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredIsolationTargetStore: TieredIsolationTargetStore {
        var inner: MemoryTieredIsolationTargetStore
        var cache: TTLCache<TieredIsolationTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredIsolationTargetStore, cache: TTLCache<TieredIsolationTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredIsolationTarget? {
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

        func save(_ item: TieredIsolationTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredIsolationTarget] {
            return inner.list()
        }
    }

    static func newCachedTieredIsolationTargetStore(_ inner: MemoryTieredIsolationTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredIsolationTargetStore {
        return CachedTieredIsolationTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered isolation targets. Empty fields match all.
    final class TieredIsolationTargetQuery {
        var unit: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredIsolationTarget) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredIsolationTarget]) -> [TieredIsolationTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredIsolationTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredIsolationTargets(_ store: any TieredIsolationTargetStore, query: TieredIsolationTargetQuery) -> [TieredIsolationTarget] {
        return query.apply(store.list())
    }
}
