import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps tiered task records by code.
    protocol TieredTaskRecordStore {
        func find(_ code: String) -> TieredTaskRecord?
        func save(_ item: TieredTaskRecord)
        func remove(_ code: String) -> Bool
        func list() -> [TieredTaskRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredTaskRecordStore: TieredTaskRecordStore {
        var items: [String: TieredTaskRecord]
        var order: [String]

        init(items: [String: TieredTaskRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredTaskRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredTaskRecord) {
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

        func list() -> [TieredTaskRecord] {
            var out: [TieredTaskRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredTaskRecordStore() -> any TieredTaskRecordStore {
        return MemoryTieredTaskRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredTaskRecordStore: TieredTaskRecordStore {
        var inner: MemoryTieredTaskRecordStore
        var cache: TTLCache<TieredTaskRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredTaskRecordStore, cache: TTLCache<TieredTaskRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredTaskRecord? {
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

        func save(_ item: TieredTaskRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredTaskRecord] {
            return inner.list()
        }
    }

    static func newCachedTieredTaskRecordStore(_ inner: MemoryTieredTaskRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredTaskRecordStore {
        return CachedTieredTaskRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered task records. Empty fields match all.
    final class TieredTaskRecordQuery {
        var ward: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredTaskRecord) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredTaskRecord]) -> [TieredTaskRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredTaskRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredTaskRecords(_ store: any TieredTaskRecordStore, query: TieredTaskRecordQuery) -> [TieredTaskRecord] {
        return query.apply(store.list())
    }
}
