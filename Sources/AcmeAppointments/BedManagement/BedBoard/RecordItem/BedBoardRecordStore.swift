import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board records by code.
    protocol BedBoardRecordStore {
        func find(_ code: String) -> BedBoardRecord?
        func save(_ item: BedBoardRecord)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardRecordStore: BedBoardRecordStore {
        var items: [String: BedBoardRecord]
        var order: [String]

        init(items: [String: BedBoardRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardRecord) {
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

        func list() -> [BedBoardRecord] {
            var out: [BedBoardRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardRecordStore() -> any BedBoardRecordStore {
        return MemoryBedBoardRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardRecordStore: BedBoardRecordStore {
        var inner: MemoryBedBoardRecordStore
        var cache: TTLCache<BedBoardRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardRecordStore, cache: TTLCache<BedBoardRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardRecord? {
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

        func save(_ item: BedBoardRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardRecord] {
            return inner.list()
        }
    }

    static func newCachedBedBoardRecordStore(_ inner: MemoryBedBoardRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardRecordStore {
        return CachedBedBoardRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board records. Empty fields match all.
    final class BedBoardRecordQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardRecord) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [BedBoardRecord]) -> [BedBoardRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardRecords(_ store: any BedBoardRecordStore, query: BedBoardRecordQuery) -> [BedBoardRecord] {
        return query.apply(store.list())
    }
}
