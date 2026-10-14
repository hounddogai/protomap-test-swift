import AcmePlatform
import Foundation

extension Labs {
    /// Keeps tiered reference range records by code.
    protocol TieredReferenceRangeRecordStore {
        func find(_ code: String) -> TieredReferenceRangeRecord?
        func save(_ item: TieredReferenceRangeRecord)
        func remove(_ code: String) -> Bool
        func list() -> [TieredReferenceRangeRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredReferenceRangeRecordStore: TieredReferenceRangeRecordStore {
        var items: [String: TieredReferenceRangeRecord]
        var order: [String]

        init(items: [String: TieredReferenceRangeRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredReferenceRangeRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredReferenceRangeRecord) {
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

        func list() -> [TieredReferenceRangeRecord] {
            var out: [TieredReferenceRangeRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredReferenceRangeRecordStore() -> any TieredReferenceRangeRecordStore {
        return MemoryTieredReferenceRangeRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredReferenceRangeRecordStore: TieredReferenceRangeRecordStore {
        var inner: MemoryTieredReferenceRangeRecordStore
        var cache: TTLCache<TieredReferenceRangeRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredReferenceRangeRecordStore, cache: TTLCache<TieredReferenceRangeRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredReferenceRangeRecord? {
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

        func save(_ item: TieredReferenceRangeRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredReferenceRangeRecord] {
            return inner.list()
        }
    }

    static func newCachedTieredReferenceRangeRecordStore(_ inner: MemoryTieredReferenceRangeRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredReferenceRangeRecordStore {
        return CachedTieredReferenceRangeRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered reference range records. Empty fields match all.
    final class TieredReferenceRangeRecordQuery {
        var region: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minPriority: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredReferenceRangeRecord) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredReferenceRangeRecord]) -> [TieredReferenceRangeRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredReferenceRangeRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredReferenceRangeRecords(_ store: any TieredReferenceRangeRecordStore, query: TieredReferenceRangeRecordQuery) -> [TieredReferenceRangeRecord] {
        return query.apply(store.list())
    }
}
