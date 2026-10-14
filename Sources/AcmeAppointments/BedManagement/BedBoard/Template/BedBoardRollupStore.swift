import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board rollups by code.
    protocol BedBoardRollupStore {
        func find(_ code: String) -> BedBoardRollup?
        func save(_ item: BedBoardRollup)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardRollupStore: BedBoardRollupStore {
        var items: [String: BedBoardRollup]
        var order: [String]

        init(items: [String: BedBoardRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardRollup) {
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

        func list() -> [BedBoardRollup] {
            var out: [BedBoardRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardRollupStore() -> any BedBoardRollupStore {
        return MemoryBedBoardRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardRollupStore: BedBoardRollupStore {
        var inner: MemoryBedBoardRollupStore
        var cache: TTLCache<BedBoardRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardRollupStore, cache: TTLCache<BedBoardRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardRollup? {
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

        func save(_ item: BedBoardRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardRollup] {
            return inner.list()
        }
    }

    static func newCachedBedBoardRollupStore(_ inner: MemoryBedBoardRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardRollupStore {
        return CachedBedBoardRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board rollups. Empty fields match all.
    final class BedBoardRollupQuery {
        var facility: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardRollup) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [BedBoardRollup]) -> [BedBoardRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardRollups(_ store: any BedBoardRollupStore, query: BedBoardRollupQuery) -> [BedBoardRollup] {
        return query.apply(store.list())
    }
}
