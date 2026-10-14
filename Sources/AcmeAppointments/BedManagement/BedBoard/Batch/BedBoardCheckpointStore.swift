import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board checkpoints by code.
    protocol BedBoardCheckpointStore {
        func find(_ code: String) -> BedBoardCheckpoint?
        func save(_ item: BedBoardCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardCheckpointStore: BedBoardCheckpointStore {
        var items: [String: BedBoardCheckpoint]
        var order: [String]

        init(items: [String: BedBoardCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardCheckpoint) {
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

        func list() -> [BedBoardCheckpoint] {
            var out: [BedBoardCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardCheckpointStore() -> any BedBoardCheckpointStore {
        return MemoryBedBoardCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardCheckpointStore: BedBoardCheckpointStore {
        var inner: MemoryBedBoardCheckpointStore
        var cache: TTLCache<BedBoardCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardCheckpointStore, cache: TTLCache<BedBoardCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardCheckpoint? {
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

        func save(_ item: BedBoardCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedBedBoardCheckpointStore(_ inner: MemoryBedBoardCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardCheckpointStore {
        return CachedBedBoardCheckpointStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board checkpoints. Empty fields match all.
    final class BedBoardCheckpointQuery {
        var segment: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardCheckpoint) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardCheckpoint]) -> [BedBoardCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardCheckpoints(_ store: any BedBoardCheckpointStore, query: BedBoardCheckpointQuery) -> [BedBoardCheckpoint] {
        return query.apply(store.list())
    }
}
