import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist records by code.
    protocol WorklistRecordStore {
        func find(_ code: String) -> WorklistRecord?
        func save(_ item: WorklistRecord)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistRecordStore: WorklistRecordStore {
        var items: [String: WorklistRecord]
        var order: [String]

        init(items: [String: WorklistRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistRecord) {
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

        func list() -> [WorklistRecord] {
            var out: [WorklistRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistRecordStore() -> any WorklistRecordStore {
        return MemoryWorklistRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistRecordStore: WorklistRecordStore {
        var inner: MemoryWorklistRecordStore
        var cache: TTLCache<WorklistRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistRecordStore, cache: TTLCache<WorklistRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistRecord? {
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

        func save(_ item: WorklistRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistRecord] {
            return inner.list()
        }
    }

    static func newCachedWorklistRecordStore(_ inner: MemoryWorklistRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistRecordStore {
        return CachedWorklistRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist records. Empty fields match all.
    final class WorklistRecordQuery {
        var label: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [WorklistRecord]) -> [WorklistRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistRecords(_ store: any WorklistRecordStore, query: WorklistRecordQuery) -> [WorklistRecord] {
        return query.apply(store.list())
    }
}
