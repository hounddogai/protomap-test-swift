import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps strict bed board cycles by code.
    protocol StrictBedBoardCycleStore {
        func find(_ code: String) -> StrictBedBoardCycle?
        func save(_ item: StrictBedBoardCycle)
        func remove(_ code: String) -> Bool
        func list() -> [StrictBedBoardCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictBedBoardCycleStore: StrictBedBoardCycleStore {
        var items: [String: StrictBedBoardCycle]
        var order: [String]

        init(items: [String: StrictBedBoardCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictBedBoardCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictBedBoardCycle) {
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

        func list() -> [StrictBedBoardCycle] {
            var out: [StrictBedBoardCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictBedBoardCycleStore() -> any StrictBedBoardCycleStore {
        return MemoryStrictBedBoardCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictBedBoardCycleStore: StrictBedBoardCycleStore {
        var inner: MemoryStrictBedBoardCycleStore
        var cache: TTLCache<StrictBedBoardCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictBedBoardCycleStore, cache: TTLCache<StrictBedBoardCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictBedBoardCycle? {
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

        func save(_ item: StrictBedBoardCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictBedBoardCycle] {
            return inner.list()
        }
    }

    static func newCachedStrictBedBoardCycleStore(_ inner: MemoryStrictBedBoardCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictBedBoardCycleStore {
        return CachedStrictBedBoardCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict bed board cycles. Empty fields match all.
    final class StrictBedBoardCycleQuery {
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

        func matches(_ item: StrictBedBoardCycle) -> Bool {
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

        func apply(_ items: [StrictBedBoardCycle]) -> [StrictBedBoardCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictBedBoardCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictBedBoardCycles(_ store: any StrictBedBoardCycleStore, query: StrictBedBoardCycleQuery) -> [StrictBedBoardCycle] {
        return query.apply(store.list())
    }
}
