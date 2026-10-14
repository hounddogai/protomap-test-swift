import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps batched overtime reservations by code.
    protocol BatchedOvertimeReservationStore {
        func find(_ code: String) -> BatchedOvertimeReservation?
        func save(_ item: BatchedOvertimeReservation)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedOvertimeReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedOvertimeReservationStore: BatchedOvertimeReservationStore {
        var items: [String: BatchedOvertimeReservation]
        var order: [String]

        init(items: [String: BatchedOvertimeReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedOvertimeReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedOvertimeReservation) {
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

        func list() -> [BatchedOvertimeReservation] {
            var out: [BatchedOvertimeReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedOvertimeReservationStore() -> any BatchedOvertimeReservationStore {
        return MemoryBatchedOvertimeReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedOvertimeReservationStore: BatchedOvertimeReservationStore {
        var inner: MemoryBatchedOvertimeReservationStore
        var cache: TTLCache<BatchedOvertimeReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedOvertimeReservationStore, cache: TTLCache<BatchedOvertimeReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedOvertimeReservation? {
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

        func save(_ item: BatchedOvertimeReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedOvertimeReservation] {
            return inner.list()
        }
    }

    static func newCachedBatchedOvertimeReservationStore(_ inner: MemoryBatchedOvertimeReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedOvertimeReservationStore {
        return CachedBatchedOvertimeReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched overtime reservations. Empty fields match all.
    final class BatchedOvertimeReservationQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedOvertimeReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedOvertimeReservation]) -> [BatchedOvertimeReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedOvertimeReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedOvertimeReservations(_ store: any BatchedOvertimeReservationStore, query: BatchedOvertimeReservationQuery) -> [BatchedOvertimeReservation] {
        return query.apply(store.list())
    }
}
