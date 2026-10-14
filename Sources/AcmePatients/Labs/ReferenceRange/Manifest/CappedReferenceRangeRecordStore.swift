import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped reference range records by code.
    protocol CappedReferenceRangeRecordStore {
        func find(_ code: String) -> CappedReferenceRangeRecord?
        func save(_ item: CappedReferenceRangeRecord)
        func remove(_ code: String) -> Bool
        func list() -> [CappedReferenceRangeRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedReferenceRangeRecordStore: CappedReferenceRangeRecordStore {
        var items: [String: CappedReferenceRangeRecord]
        var order: [String]

        init(items: [String: CappedReferenceRangeRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedReferenceRangeRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedReferenceRangeRecord) {
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

        func list() -> [CappedReferenceRangeRecord] {
            var out: [CappedReferenceRangeRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedReferenceRangeRecordStore() -> any CappedReferenceRangeRecordStore {
        return MemoryCappedReferenceRangeRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedReferenceRangeRecordStore: CappedReferenceRangeRecordStore {
        var inner: MemoryCappedReferenceRangeRecordStore
        var cache: TTLCache<CappedReferenceRangeRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedReferenceRangeRecordStore, cache: TTLCache<CappedReferenceRangeRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedReferenceRangeRecord? {
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

        func save(_ item: CappedReferenceRangeRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedReferenceRangeRecord] {
            return inner.list()
        }
    }

    static func newCachedCappedReferenceRangeRecordStore(_ inner: MemoryCappedReferenceRangeRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedReferenceRangeRecordStore {
        return CachedCappedReferenceRangeRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped reference range records. Empty fields match all.
    final class CappedReferenceRangeRecordQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedReferenceRangeRecord) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedReferenceRangeRecord]) -> [CappedReferenceRangeRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedReferenceRangeRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedReferenceRangeRecords(_ store: any CappedReferenceRangeRecordStore, query: CappedReferenceRangeRecordQuery) -> [CappedReferenceRangeRecord] {
        return query.apply(store.list())
    }
}
