import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal slot records by code.
    protocol SeasonalSlotRecordStore {
        func find(_ code: String) -> SeasonalSlotRecord?
        func save(_ item: SeasonalSlotRecord)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalSlotRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalSlotRecordStore: SeasonalSlotRecordStore {
        var items: [String: SeasonalSlotRecord]
        var order: [String]

        init(items: [String: SeasonalSlotRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalSlotRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalSlotRecord) {
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

        func list() -> [SeasonalSlotRecord] {
            var out: [SeasonalSlotRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalSlotRecordStore() -> any SeasonalSlotRecordStore {
        return MemorySeasonalSlotRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalSlotRecordStore: SeasonalSlotRecordStore {
        var inner: MemorySeasonalSlotRecordStore
        var cache: TTLCache<SeasonalSlotRecord>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalSlotRecordStore, cache: TTLCache<SeasonalSlotRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalSlotRecord? {
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

        func save(_ item: SeasonalSlotRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalSlotRecord] {
            return inner.list()
        }
    }

    static func newCachedSeasonalSlotRecordStore(_ inner: MemorySeasonalSlotRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalSlotRecordStore {
        return CachedSeasonalSlotRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal slot records. Empty fields match all.
    final class SeasonalSlotRecordQuery {
        var ward: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalSlotRecord) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [SeasonalSlotRecord]) -> [SeasonalSlotRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalSlotRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalSlotRecords(_ store: any SeasonalSlotRecordStore, query: SeasonalSlotRecordQuery) -> [SeasonalSlotRecord] {
        return query.apply(store.list())
    }
}
