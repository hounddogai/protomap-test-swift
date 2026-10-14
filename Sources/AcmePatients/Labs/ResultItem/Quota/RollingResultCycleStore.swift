import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling result cycles by code.
    protocol RollingResultCycleStore {
        func find(_ code: String) -> RollingResultCycle?
        func save(_ item: RollingResultCycle)
        func remove(_ code: String) -> Bool
        func list() -> [RollingResultCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingResultCycleStore: RollingResultCycleStore {
        var items: [String: RollingResultCycle]
        var order: [String]

        init(items: [String: RollingResultCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingResultCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingResultCycle) {
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

        func list() -> [RollingResultCycle] {
            var out: [RollingResultCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingResultCycleStore() -> any RollingResultCycleStore {
        return MemoryRollingResultCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingResultCycleStore: RollingResultCycleStore {
        var inner: MemoryRollingResultCycleStore
        var cache: TTLCache<RollingResultCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingResultCycleStore, cache: TTLCache<RollingResultCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingResultCycle? {
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

        func save(_ item: RollingResultCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingResultCycle] {
            return inner.list()
        }
    }

    static func newCachedRollingResultCycleStore(_ inner: MemoryRollingResultCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingResultCycleStore {
        return CachedRollingResultCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling result cycles. Empty fields match all.
    final class RollingResultCycleQuery {
        var ward: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRefills: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingResultCycle) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingResultCycle]) -> [RollingResultCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingResultCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingResultCycles(_ store: any RollingResultCycleStore, query: RollingResultCycleQuery) -> [RollingResultCycle] {
        return query.apply(store.list())
    }
}
