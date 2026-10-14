import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal eligibility records by code.
    protocol SeasonalEligibilityRecordStore {
        func find(_ code: String) -> SeasonalEligibilityRecord?
        func save(_ item: SeasonalEligibilityRecord)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalEligibilityRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalEligibilityRecordStore: SeasonalEligibilityRecordStore {
        var items: [String: SeasonalEligibilityRecord]
        var order: [String]

        init(items: [String: SeasonalEligibilityRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalEligibilityRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalEligibilityRecord) {
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

        func list() -> [SeasonalEligibilityRecord] {
            var out: [SeasonalEligibilityRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalEligibilityRecordStore() -> any SeasonalEligibilityRecordStore {
        return MemorySeasonalEligibilityRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalEligibilityRecordStore: SeasonalEligibilityRecordStore {
        var inner: MemorySeasonalEligibilityRecordStore
        var cache: TTLCache<SeasonalEligibilityRecord>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalEligibilityRecordStore, cache: TTLCache<SeasonalEligibilityRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalEligibilityRecord? {
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

        func save(_ item: SeasonalEligibilityRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalEligibilityRecord] {
            return inner.list()
        }
    }

    static func newCachedSeasonalEligibilityRecordStore(_ inner: MemorySeasonalEligibilityRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalEligibilityRecordStore {
        return CachedSeasonalEligibilityRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal eligibility records. Empty fields match all.
    final class SeasonalEligibilityRecordQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalEligibilityRecord) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalEligibilityRecord]) -> [SeasonalEligibilityRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalEligibilityRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalEligibilityRecords(_ store: any SeasonalEligibilityRecordStore, query: SeasonalEligibilityRecordQuery) -> [SeasonalEligibilityRecord] {
        return query.apply(store.list())
    }
}
