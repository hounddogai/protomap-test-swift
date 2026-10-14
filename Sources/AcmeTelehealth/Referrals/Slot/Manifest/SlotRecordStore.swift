import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot records by code.
    protocol SlotRecordStore {
        func find(_ code: String) -> SlotRecord?
        func save(_ item: SlotRecord)
        func remove(_ code: String) -> Bool
        func list() -> [SlotRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotRecordStore: SlotRecordStore {
        var items: [String: SlotRecord]
        var order: [String]

        init(items: [String: SlotRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotRecord) {
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

        func list() -> [SlotRecord] {
            var out: [SlotRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotRecordStore() -> any SlotRecordStore {
        return MemorySlotRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotRecordStore: SlotRecordStore {
        var inner: MemorySlotRecordStore
        var cache: TTLCache<SlotRecord>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotRecordStore, cache: TTLCache<SlotRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotRecord? {
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

        func save(_ item: SlotRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotRecord] {
            return inner.list()
        }
    }

    static func newCachedSlotRecordStore(_ inner: MemorySlotRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotRecordStore {
        return CachedSlotRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot records. Empty fields match all.
    final class SlotRecordQuery {
        var facility: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minBudget: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotRecord) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotRecord]) -> [SlotRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotRecords(_ store: any SlotRecordStore, query: SlotRecordQuery) -> [SlotRecord] {
        return query.apply(store.list())
    }
}
