import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board thresholds by code.
    protocol BedBoardThresholdStore {
        func find(_ code: String) -> BedBoardThreshold?
        func save(_ item: BedBoardThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardThresholdStore: BedBoardThresholdStore {
        var items: [String: BedBoardThreshold]
        var order: [String]

        init(items: [String: BedBoardThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardThreshold) {
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

        func list() -> [BedBoardThreshold] {
            var out: [BedBoardThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardThresholdStore() -> any BedBoardThresholdStore {
        return MemoryBedBoardThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardThresholdStore: BedBoardThresholdStore {
        var inner: MemoryBedBoardThresholdStore
        var cache: TTLCache<BedBoardThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardThresholdStore, cache: TTLCache<BedBoardThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardThreshold? {
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

        func save(_ item: BedBoardThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardThreshold] {
            return inner.list()
        }
    }

    static func newCachedBedBoardThresholdStore(_ inner: MemoryBedBoardThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardThresholdStore {
        return CachedBedBoardThresholdStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board thresholds. Empty fields match all.
    final class BedBoardThresholdQuery {
        var facility: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardThreshold) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardThreshold]) -> [BedBoardThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardThresholds(_ store: any BedBoardThresholdStore, query: BedBoardThresholdQuery) -> [BedBoardThreshold] {
        return query.apply(store.list())
    }
}
