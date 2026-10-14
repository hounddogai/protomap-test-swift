import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy statement records by code.
    protocol LegacyStatementRecordStore {
        func find(_ code: String) -> LegacyStatementRecord?
        func save(_ item: LegacyStatementRecord)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyStatementRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyStatementRecordStore: LegacyStatementRecordStore {
        var items: [String: LegacyStatementRecord]
        var order: [String]

        init(items: [String: LegacyStatementRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyStatementRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyStatementRecord) {
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

        func list() -> [LegacyStatementRecord] {
            var out: [LegacyStatementRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyStatementRecordStore() -> any LegacyStatementRecordStore {
        return MemoryLegacyStatementRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyStatementRecordStore: LegacyStatementRecordStore {
        var inner: MemoryLegacyStatementRecordStore
        var cache: TTLCache<LegacyStatementRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyStatementRecordStore, cache: TTLCache<LegacyStatementRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyStatementRecord? {
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

        func save(_ item: LegacyStatementRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyStatementRecord] {
            return inner.list()
        }
    }

    static func newCachedLegacyStatementRecordStore(_ inner: MemoryLegacyStatementRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyStatementRecordStore {
        return CachedLegacyStatementRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy statement records. Empty fields match all.
    final class LegacyStatementRecordQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyStatementRecord) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyStatementRecord]) -> [LegacyStatementRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyStatementRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyStatementRecords(_ store: any LegacyStatementRecordStore, query: LegacyStatementRecordQuery) -> [LegacyStatementRecord] {
        return query.apply(store.list())
    }
}
