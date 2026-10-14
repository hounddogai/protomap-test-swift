import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift batches by code.
    protocol ShiftBatchStore {
        func find(_ code: String) -> ShiftBatch?
        func save(_ item: ShiftBatch)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftBatchStore: ShiftBatchStore {
        var items: [String: ShiftBatch]
        var order: [String]

        init(items: [String: ShiftBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftBatch) {
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

        func list() -> [ShiftBatch] {
            var out: [ShiftBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftBatchStore() -> any ShiftBatchStore {
        return MemoryShiftBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftBatchStore: ShiftBatchStore {
        var inner: MemoryShiftBatchStore
        var cache: TTLCache<ShiftBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftBatchStore, cache: TTLCache<ShiftBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftBatch? {
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

        func save(_ item: ShiftBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftBatch] {
            return inner.list()
        }
    }

    static func newCachedShiftBatchStore(_ inner: MemoryShiftBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftBatchStore {
        return CachedShiftBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift batches. Empty fields match all.
    final class ShiftBatchQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftBatch) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ShiftBatch]) -> [ShiftBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftBatches(_ store: any ShiftBatchStore, query: ShiftBatchQuery) -> [ShiftBatch] {
        return query.apply(store.list())
    }
}
