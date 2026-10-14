import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board cycles by code.
    protocol BedBoardCycleStore {
        func find(_ code: String) -> BedBoardCycle?
        func save(_ item: BedBoardCycle)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardCycleStore: BedBoardCycleStore {
        var items: [String: BedBoardCycle]
        var order: [String]

        init(items: [String: BedBoardCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardCycle) {
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

        func list() -> [BedBoardCycle] {
            var out: [BedBoardCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardCycleStore() -> any BedBoardCycleStore {
        return MemoryBedBoardCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardCycleStore: BedBoardCycleStore {
        var inner: MemoryBedBoardCycleStore
        var cache: TTLCache<BedBoardCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardCycleStore, cache: TTLCache<BedBoardCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardCycle? {
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

        func save(_ item: BedBoardCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardCycle] {
            return inner.list()
        }
    }

    static func newCachedBedBoardCycleStore(_ inner: MemoryBedBoardCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardCycleStore {
        return CachedBedBoardCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board cycles. Empty fields match all.
    final class BedBoardCycleQuery {
        var region: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardCycle) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardCycle]) -> [BedBoardCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardCycles(_ store: any BedBoardCycleStore, query: BedBoardCycleQuery) -> [BedBoardCycle] {
        return query.apply(store.list())
    }
}
