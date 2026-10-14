import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board requests by code.
    protocol BedBoardRequestStore {
        func find(_ code: String) -> BedBoardRequest?
        func save(_ item: BedBoardRequest)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardRequestStore: BedBoardRequestStore {
        var items: [String: BedBoardRequest]
        var order: [String]

        init(items: [String: BedBoardRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardRequest) {
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

        func list() -> [BedBoardRequest] {
            var out: [BedBoardRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardRequestStore() -> any BedBoardRequestStore {
        return MemoryBedBoardRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardRequestStore: BedBoardRequestStore {
        var inner: MemoryBedBoardRequestStore
        var cache: TTLCache<BedBoardRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardRequestStore, cache: TTLCache<BedBoardRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardRequest? {
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

        func save(_ item: BedBoardRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardRequest] {
            return inner.list()
        }
    }

    static func newCachedBedBoardRequestStore(_ inner: MemoryBedBoardRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardRequestStore {
        return CachedBedBoardRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board requests. Empty fields match all.
    final class BedBoardRequestQuery {
        var region: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minWeight: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardRequest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [BedBoardRequest]) -> [BedBoardRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardRequests(_ store: any BedBoardRequestStore, query: BedBoardRequestQuery) -> [BedBoardRequest] {
        return query.apply(store.list())
    }
}
