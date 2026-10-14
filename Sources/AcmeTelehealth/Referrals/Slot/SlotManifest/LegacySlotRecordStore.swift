import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps legacy slot records by code.
    protocol LegacySlotRecordStore {
        func find(_ code: String) -> LegacySlotRecord?
        func save(_ item: LegacySlotRecord)
        func remove(_ code: String) -> Bool
        func list() -> [LegacySlotRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacySlotRecordStore: LegacySlotRecordStore {
        var items: [String: LegacySlotRecord]
        var order: [String]

        init(items: [String: LegacySlotRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacySlotRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacySlotRecord) {
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

        func list() -> [LegacySlotRecord] {
            var out: [LegacySlotRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacySlotRecordStore() -> any LegacySlotRecordStore {
        return MemoryLegacySlotRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacySlotRecordStore: LegacySlotRecordStore {
        var inner: MemoryLegacySlotRecordStore
        var cache: TTLCache<LegacySlotRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacySlotRecordStore, cache: TTLCache<LegacySlotRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacySlotRecord? {
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

        func save(_ item: LegacySlotRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacySlotRecord] {
            return inner.list()
        }
    }

    static func newCachedLegacySlotRecordStore(_ inner: MemoryLegacySlotRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacySlotRecordStore {
        return CachedLegacySlotRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy slot records. Empty fields match all.
    final class LegacySlotRecordQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacySlotRecord) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacySlotRecord]) -> [LegacySlotRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacySlotRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacySlotRecords(_ store: any LegacySlotRecordStore, query: LegacySlotRecordQuery) -> [LegacySlotRecord] {
        return query.apply(store.list())
    }
}
