import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory records by code.
    protocol InventoryRecordStore {
        func find(_ code: String) -> InventoryRecord?
        func save(_ item: InventoryRecord)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryRecordStore: InventoryRecordStore {
        var items: [String: InventoryRecord]
        var order: [String]

        init(items: [String: InventoryRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryRecord) {
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

        func list() -> [InventoryRecord] {
            var out: [InventoryRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryRecordStore() -> any InventoryRecordStore {
        return MemoryInventoryRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryRecordStore: InventoryRecordStore {
        var inner: MemoryInventoryRecordStore
        var cache: TTLCache<InventoryRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryRecordStore, cache: TTLCache<InventoryRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryRecord? {
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

        func save(_ item: InventoryRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryRecord] {
            return inner.list()
        }
    }

    static func newCachedInventoryRecordStore(_ inner: MemoryInventoryRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryRecordStore {
        return CachedInventoryRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory records. Empty fields match all.
    final class InventoryRecordQuery {
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

        func matches(_ item: InventoryRecord) -> Bool {
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

        func apply(_ items: [InventoryRecord]) -> [InventoryRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryRecords(_ store: any InventoryRecordStore, query: InventoryRecordQuery) -> [InventoryRecord] {
        return query.apply(store.list())
    }
}
