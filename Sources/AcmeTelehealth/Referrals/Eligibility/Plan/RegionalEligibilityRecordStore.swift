import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional eligibility records by code.
    protocol RegionalEligibilityRecordStore {
        func find(_ code: String) -> RegionalEligibilityRecord?
        func save(_ item: RegionalEligibilityRecord)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalEligibilityRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalEligibilityRecordStore: RegionalEligibilityRecordStore {
        var items: [String: RegionalEligibilityRecord]
        var order: [String]

        init(items: [String: RegionalEligibilityRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalEligibilityRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalEligibilityRecord) {
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

        func list() -> [RegionalEligibilityRecord] {
            var out: [RegionalEligibilityRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalEligibilityRecordStore() -> any RegionalEligibilityRecordStore {
        return MemoryRegionalEligibilityRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalEligibilityRecordStore: RegionalEligibilityRecordStore {
        var inner: MemoryRegionalEligibilityRecordStore
        var cache: TTLCache<RegionalEligibilityRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalEligibilityRecordStore, cache: TTLCache<RegionalEligibilityRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalEligibilityRecord? {
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

        func save(_ item: RegionalEligibilityRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalEligibilityRecord] {
            return inner.list()
        }
    }

    static func newCachedRegionalEligibilityRecordStore(_ inner: MemoryRegionalEligibilityRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalEligibilityRecordStore {
        return CachedRegionalEligibilityRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional eligibility records. Empty fields match all.
    final class RegionalEligibilityRecordQuery {
        var category: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalEligibilityRecord) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalEligibilityRecord]) -> [RegionalEligibilityRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalEligibilityRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalEligibilityRecords(_ store: any RegionalEligibilityRecordStore, query: RegionalEligibilityRecordQuery) -> [RegionalEligibilityRecord] {
        return query.apply(store.list())
    }
}
