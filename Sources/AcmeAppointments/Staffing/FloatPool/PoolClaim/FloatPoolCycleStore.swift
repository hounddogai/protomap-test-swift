import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool cycles by code.
    protocol FloatPoolCycleStore {
        func find(_ code: String) -> FloatPoolCycle?
        func save(_ item: FloatPoolCycle)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolCycleStore: FloatPoolCycleStore {
        var items: [String: FloatPoolCycle]
        var order: [String]

        init(items: [String: FloatPoolCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolCycle) {
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

        func list() -> [FloatPoolCycle] {
            var out: [FloatPoolCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolCycleStore() -> any FloatPoolCycleStore {
        return MemoryFloatPoolCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolCycleStore: FloatPoolCycleStore {
        var inner: MemoryFloatPoolCycleStore
        var cache: TTLCache<FloatPoolCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolCycleStore, cache: TTLCache<FloatPoolCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolCycle? {
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

        func save(_ item: FloatPoolCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolCycle] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolCycleStore(_ inner: MemoryFloatPoolCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolCycleStore {
        return CachedFloatPoolCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool cycles. Empty fields match all.
    final class FloatPoolCycleQuery {
        var facility: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minWeight: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolCycle) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolCycle]) -> [FloatPoolCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolCycles(_ store: any FloatPoolCycleStore, query: FloatPoolCycleQuery) -> [FloatPoolCycle] {
        return query.apply(store.list())
    }
}
