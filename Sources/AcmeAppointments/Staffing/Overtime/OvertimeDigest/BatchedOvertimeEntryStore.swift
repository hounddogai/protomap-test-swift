import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps batched overtime entries by code.
    protocol BatchedOvertimeEntryStore {
        func find(_ code: String) -> BatchedOvertimeEntry?
        func save(_ item: BatchedOvertimeEntry)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedOvertimeEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedOvertimeEntryStore: BatchedOvertimeEntryStore {
        var items: [String: BatchedOvertimeEntry]
        var order: [String]

        init(items: [String: BatchedOvertimeEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedOvertimeEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedOvertimeEntry) {
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

        func list() -> [BatchedOvertimeEntry] {
            var out: [BatchedOvertimeEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedOvertimeEntryStore() -> any BatchedOvertimeEntryStore {
        return MemoryBatchedOvertimeEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedOvertimeEntryStore: BatchedOvertimeEntryStore {
        var inner: MemoryBatchedOvertimeEntryStore
        var cache: TTLCache<BatchedOvertimeEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedOvertimeEntryStore, cache: TTLCache<BatchedOvertimeEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedOvertimeEntry? {
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

        func save(_ item: BatchedOvertimeEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedOvertimeEntry] {
            return inner.list()
        }
    }

    static func newCachedBatchedOvertimeEntryStore(_ inner: MemoryBatchedOvertimeEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedOvertimeEntryStore {
        return CachedBatchedOvertimeEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched overtime entries. Empty fields match all.
    final class BatchedOvertimeEntryQuery {
        var country: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedOvertimeEntry) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedOvertimeEntry]) -> [BatchedOvertimeEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedOvertimeEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedOvertimeEntries(_ store: any BatchedOvertimeEntryStore, query: BatchedOvertimeEntryQuery) -> [BatchedOvertimeEntry] {
        return query.apply(store.list())
    }
}
