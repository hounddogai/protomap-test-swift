import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual remittance records by code.
    protocol ManualRemittanceRecordStore {
        func find(_ code: String) -> ManualRemittanceRecord?
        func save(_ item: ManualRemittanceRecord)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRemittanceRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRemittanceRecordStore: ManualRemittanceRecordStore {
        var items: [String: ManualRemittanceRecord]
        var order: [String]

        init(items: [String: ManualRemittanceRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRemittanceRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRemittanceRecord) {
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

        func list() -> [ManualRemittanceRecord] {
            var out: [ManualRemittanceRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRemittanceRecordStore() -> any ManualRemittanceRecordStore {
        return MemoryManualRemittanceRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRemittanceRecordStore: ManualRemittanceRecordStore {
        var inner: MemoryManualRemittanceRecordStore
        var cache: TTLCache<ManualRemittanceRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRemittanceRecordStore, cache: TTLCache<ManualRemittanceRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRemittanceRecord? {
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

        func save(_ item: ManualRemittanceRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRemittanceRecord] {
            return inner.list()
        }
    }

    static func newCachedManualRemittanceRecordStore(_ inner: MemoryManualRemittanceRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRemittanceRecordStore {
        return CachedManualRemittanceRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual remittance records. Empty fields match all.
    final class ManualRemittanceRecordQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRemittanceRecord) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ManualRemittanceRecord]) -> [ManualRemittanceRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRemittanceRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRemittanceRecords(_ store: any ManualRemittanceRecordStore, query: ManualRemittanceRecordQuery) -> [ManualRemittanceRecord] {
        return query.apply(store.list())
    }
}
