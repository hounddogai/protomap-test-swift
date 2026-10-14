import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped bed board records by code.
    protocol CappedBedBoardRecordStore {
        func find(_ code: String) -> CappedBedBoardRecord?
        func save(_ item: CappedBedBoardRecord)
        func remove(_ code: String) -> Bool
        func list() -> [CappedBedBoardRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedBedBoardRecordStore: CappedBedBoardRecordStore {
        var items: [String: CappedBedBoardRecord]
        var order: [String]

        init(items: [String: CappedBedBoardRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedBedBoardRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedBedBoardRecord) {
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

        func list() -> [CappedBedBoardRecord] {
            var out: [CappedBedBoardRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedBedBoardRecordStore() -> any CappedBedBoardRecordStore {
        return MemoryCappedBedBoardRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedBedBoardRecordStore: CappedBedBoardRecordStore {
        var inner: MemoryCappedBedBoardRecordStore
        var cache: TTLCache<CappedBedBoardRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedBedBoardRecordStore, cache: TTLCache<CappedBedBoardRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedBedBoardRecord? {
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

        func save(_ item: CappedBedBoardRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedBedBoardRecord] {
            return inner.list()
        }
    }

    static func newCachedCappedBedBoardRecordStore(_ inner: MemoryCappedBedBoardRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedBedBoardRecordStore {
        return CachedCappedBedBoardRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped bed board records. Empty fields match all.
    final class CappedBedBoardRecordQuery {
        var segment: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCopay: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedBedBoardRecord) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedBedBoardRecord]) -> [CappedBedBoardRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedBedBoardRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedBedBoardRecords(_ store: any CappedBedBoardRecordStore, query: CappedBedBoardRecordQuery) -> [CappedBedBoardRecord] {
        return query.apply(store.list())
    }
}
