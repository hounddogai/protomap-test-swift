import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered eligibility records by code.
    protocol TieredEligibilityRecordStore {
        func find(_ code: String) -> TieredEligibilityRecord?
        func save(_ item: TieredEligibilityRecord)
        func remove(_ code: String) -> Bool
        func list() -> [TieredEligibilityRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredEligibilityRecordStore: TieredEligibilityRecordStore {
        var items: [String: TieredEligibilityRecord]
        var order: [String]

        init(items: [String: TieredEligibilityRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredEligibilityRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredEligibilityRecord) {
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

        func list() -> [TieredEligibilityRecord] {
            var out: [TieredEligibilityRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredEligibilityRecordStore() -> any TieredEligibilityRecordStore {
        return MemoryTieredEligibilityRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredEligibilityRecordStore: TieredEligibilityRecordStore {
        var inner: MemoryTieredEligibilityRecordStore
        var cache: TTLCache<TieredEligibilityRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredEligibilityRecordStore, cache: TTLCache<TieredEligibilityRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredEligibilityRecord? {
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

        func save(_ item: TieredEligibilityRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredEligibilityRecord] {
            return inner.list()
        }
    }

    static func newCachedTieredEligibilityRecordStore(_ inner: MemoryTieredEligibilityRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredEligibilityRecordStore {
        return CachedTieredEligibilityRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered eligibility records. Empty fields match all.
    final class TieredEligibilityRecordQuery {
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

        func matches(_ item: TieredEligibilityRecord) -> Bool {
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

        func apply(_ items: [TieredEligibilityRecord]) -> [TieredEligibilityRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredEligibilityRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredEligibilityRecords(_ store: any TieredEligibilityRecordStore, query: TieredEligibilityRecordQuery) -> [TieredEligibilityRecord] {
        return query.apply(store.list())
    }
}
