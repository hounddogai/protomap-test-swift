import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps scheduled overtime records by code.
    protocol ScheduledOvertimeRecordStore {
        func find(_ code: String) -> ScheduledOvertimeRecord?
        func save(_ item: ScheduledOvertimeRecord)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledOvertimeRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledOvertimeRecordStore: ScheduledOvertimeRecordStore {
        var items: [String: ScheduledOvertimeRecord]
        var order: [String]

        init(items: [String: ScheduledOvertimeRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledOvertimeRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledOvertimeRecord) {
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

        func list() -> [ScheduledOvertimeRecord] {
            var out: [ScheduledOvertimeRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledOvertimeRecordStore() -> any ScheduledOvertimeRecordStore {
        return MemoryScheduledOvertimeRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledOvertimeRecordStore: ScheduledOvertimeRecordStore {
        var inner: MemoryScheduledOvertimeRecordStore
        var cache: TTLCache<ScheduledOvertimeRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledOvertimeRecordStore, cache: TTLCache<ScheduledOvertimeRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledOvertimeRecord? {
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

        func save(_ item: ScheduledOvertimeRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledOvertimeRecord] {
            return inner.list()
        }
    }

    static func newCachedScheduledOvertimeRecordStore(_ inner: MemoryScheduledOvertimeRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledOvertimeRecordStore {
        return CachedScheduledOvertimeRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled overtime records. Empty fields match all.
    final class ScheduledOvertimeRecordQuery {
        var facility: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledOvertimeRecord) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledOvertimeRecord]) -> [ScheduledOvertimeRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledOvertimeRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledOvertimeRecords(_ store: any ScheduledOvertimeRecordStore, query: ScheduledOvertimeRecordQuery) -> [ScheduledOvertimeRecord] {
        return query.apply(store.list())
    }
}
