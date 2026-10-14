import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps strict slot records by code.
    protocol StrictSlotRecordStore {
        func find(_ code: String) -> StrictSlotRecord?
        func save(_ item: StrictSlotRecord)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSlotRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSlotRecordStore: StrictSlotRecordStore {
        var items: [String: StrictSlotRecord]
        var order: [String]

        init(items: [String: StrictSlotRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSlotRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSlotRecord) {
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

        func list() -> [StrictSlotRecord] {
            var out: [StrictSlotRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSlotRecordStore() -> any StrictSlotRecordStore {
        return MemoryStrictSlotRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSlotRecordStore: StrictSlotRecordStore {
        var inner: MemoryStrictSlotRecordStore
        var cache: TTLCache<StrictSlotRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSlotRecordStore, cache: TTLCache<StrictSlotRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSlotRecord? {
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

        func save(_ item: StrictSlotRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSlotRecord] {
            return inner.list()
        }
    }

    static func newCachedStrictSlotRecordStore(_ inner: MemoryStrictSlotRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSlotRecordStore {
        return CachedStrictSlotRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict slot records. Empty fields match all.
    final class StrictSlotRecordQuery {
        var label: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSlotRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSlotRecord]) -> [StrictSlotRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSlotRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSlotRecords(_ store: any StrictSlotRecordStore, query: StrictSlotRecordQuery) -> [StrictSlotRecord] {
        return query.apply(store.list())
    }
}
