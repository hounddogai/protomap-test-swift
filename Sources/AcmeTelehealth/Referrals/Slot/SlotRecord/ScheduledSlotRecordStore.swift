import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled slot records by code.
    protocol ScheduledSlotRecordStore {
        func find(_ code: String) -> ScheduledSlotRecord?
        func save(_ item: ScheduledSlotRecord)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledSlotRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledSlotRecordStore: ScheduledSlotRecordStore {
        var items: [String: ScheduledSlotRecord]
        var order: [String]

        init(items: [String: ScheduledSlotRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledSlotRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledSlotRecord) {
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

        func list() -> [ScheduledSlotRecord] {
            var out: [ScheduledSlotRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledSlotRecordStore() -> any ScheduledSlotRecordStore {
        return MemoryScheduledSlotRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledSlotRecordStore: ScheduledSlotRecordStore {
        var inner: MemoryScheduledSlotRecordStore
        var cache: TTLCache<ScheduledSlotRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledSlotRecordStore, cache: TTLCache<ScheduledSlotRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledSlotRecord? {
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

        func save(_ item: ScheduledSlotRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledSlotRecord] {
            return inner.list()
        }
    }

    static func newCachedScheduledSlotRecordStore(_ inner: MemoryScheduledSlotRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledSlotRecordStore {
        return CachedScheduledSlotRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled slot records. Empty fields match all.
    final class ScheduledSlotRecordQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledSlotRecord) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledSlotRecord]) -> [ScheduledSlotRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledSlotRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledSlotRecords(_ store: any ScheduledSlotRecordStore, query: ScheduledSlotRecordQuery) -> [ScheduledSlotRecord] {
        return query.apply(store.list())
    }
}
