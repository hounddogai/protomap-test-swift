import AcmePlatform
import Foundation

extension Labs {
    /// Keeps manual reference range records by code.
    protocol ManualReferenceRangeRecordStore {
        func find(_ code: String) -> ManualReferenceRangeRecord?
        func save(_ item: ManualReferenceRangeRecord)
        func remove(_ code: String) -> Bool
        func list() -> [ManualReferenceRangeRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualReferenceRangeRecordStore: ManualReferenceRangeRecordStore {
        var items: [String: ManualReferenceRangeRecord]
        var order: [String]

        init(items: [String: ManualReferenceRangeRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualReferenceRangeRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualReferenceRangeRecord) {
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

        func list() -> [ManualReferenceRangeRecord] {
            var out: [ManualReferenceRangeRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualReferenceRangeRecordStore() -> any ManualReferenceRangeRecordStore {
        return MemoryManualReferenceRangeRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualReferenceRangeRecordStore: ManualReferenceRangeRecordStore {
        var inner: MemoryManualReferenceRangeRecordStore
        var cache: TTLCache<ManualReferenceRangeRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualReferenceRangeRecordStore, cache: TTLCache<ManualReferenceRangeRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualReferenceRangeRecord? {
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

        func save(_ item: ManualReferenceRangeRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualReferenceRangeRecord] {
            return inner.list()
        }
    }

    static func newCachedManualReferenceRangeRecordStore(_ inner: MemoryManualReferenceRangeRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualReferenceRangeRecordStore {
        return CachedManualReferenceRangeRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual reference range records. Empty fields match all.
    final class ManualReferenceRangeRecordQuery {
        var label: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualReferenceRangeRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualReferenceRangeRecord]) -> [ManualReferenceRangeRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualReferenceRangeRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualReferenceRangeRecords(_ store: any ManualReferenceRangeRecordStore, query: ManualReferenceRangeRecordQuery) -> [ManualReferenceRangeRecord] {
        return query.apply(store.list())
    }
}
