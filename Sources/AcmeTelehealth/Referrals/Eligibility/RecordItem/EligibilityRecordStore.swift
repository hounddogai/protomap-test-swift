import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility records by code.
    protocol EligibilityRecordStore {
        func find(_ code: String) -> EligibilityRecord?
        func save(_ item: EligibilityRecord)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityRecordStore: EligibilityRecordStore {
        var items: [String: EligibilityRecord]
        var order: [String]

        init(items: [String: EligibilityRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityRecord) {
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

        func list() -> [EligibilityRecord] {
            var out: [EligibilityRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityRecordStore() -> any EligibilityRecordStore {
        return MemoryEligibilityRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityRecordStore: EligibilityRecordStore {
        var inner: MemoryEligibilityRecordStore
        var cache: TTLCache<EligibilityRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityRecordStore, cache: TTLCache<EligibilityRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityRecord? {
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

        func save(_ item: EligibilityRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityRecord] {
            return inner.list()
        }
    }

    static func newCachedEligibilityRecordStore(_ inner: MemoryEligibilityRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityRecordStore {
        return CachedEligibilityRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility records. Empty fields match all.
    final class EligibilityRecordQuery {
        var title: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRevision: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityRecord) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityRecord]) -> [EligibilityRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityRecords(_ store: any EligibilityRecordStore, query: EligibilityRecordQuery) -> [EligibilityRecord] {
        return query.apply(store.list())
    }
}
