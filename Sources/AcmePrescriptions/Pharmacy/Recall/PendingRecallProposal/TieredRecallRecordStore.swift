import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps tiered recall records by code.
    protocol TieredRecallRecordStore {
        func find(_ code: String) -> TieredRecallRecord?
        func save(_ item: TieredRecallRecord)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRecallRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRecallRecordStore: TieredRecallRecordStore {
        var items: [String: TieredRecallRecord]
        var order: [String]

        init(items: [String: TieredRecallRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRecallRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRecallRecord) {
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

        func list() -> [TieredRecallRecord] {
            var out: [TieredRecallRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRecallRecordStore() -> any TieredRecallRecordStore {
        return MemoryTieredRecallRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRecallRecordStore: TieredRecallRecordStore {
        var inner: MemoryTieredRecallRecordStore
        var cache: TTLCache<TieredRecallRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRecallRecordStore, cache: TTLCache<TieredRecallRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRecallRecord? {
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

        func save(_ item: TieredRecallRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRecallRecord] {
            return inner.list()
        }
    }

    static func newCachedTieredRecallRecordStore(_ inner: MemoryTieredRecallRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRecallRecordStore {
        return CachedTieredRecallRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered recall records. Empty fields match all.
    final class TieredRecallRecordQuery {
        var category: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minAmount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRecallRecord) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [TieredRecallRecord]) -> [TieredRecallRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRecallRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRecallRecords(_ store: any TieredRecallRecordStore, query: TieredRecallRecordQuery) -> [TieredRecallRecord] {
        return query.apply(store.list())
    }
}
