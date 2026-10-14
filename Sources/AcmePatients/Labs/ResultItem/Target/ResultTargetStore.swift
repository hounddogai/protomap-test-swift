import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result targets by code.
    protocol ResultTargetStore {
        func find(_ code: String) -> ResultTarget?
        func save(_ item: ResultTarget)
        func remove(_ code: String) -> Bool
        func list() -> [ResultTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultTargetStore: ResultTargetStore {
        var items: [String: ResultTarget]
        var order: [String]

        init(items: [String: ResultTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultTarget) {
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

        func list() -> [ResultTarget] {
            var out: [ResultTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultTargetStore() -> any ResultTargetStore {
        return MemoryResultTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultTargetStore: ResultTargetStore {
        var inner: MemoryResultTargetStore
        var cache: TTLCache<ResultTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultTargetStore, cache: TTLCache<ResultTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultTarget? {
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

        func save(_ item: ResultTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultTarget] {
            return inner.list()
        }
    }

    static func newCachedResultTargetStore(_ inner: MemoryResultTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultTargetStore {
        return CachedResultTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result targets. Empty fields match all.
    final class ResultTargetQuery {
        var facility: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultTarget) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultTarget]) -> [ResultTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultTargets(_ store: any ResultTargetStore, query: ResultTargetQuery) -> [ResultTarget] {
        return query.apply(store.list())
    }
}
