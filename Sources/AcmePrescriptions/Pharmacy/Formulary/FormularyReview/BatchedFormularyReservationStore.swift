import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps batched formulary reservations by code.
    protocol BatchedFormularyReservationStore {
        func find(_ code: String) -> BatchedFormularyReservation?
        func save(_ item: BatchedFormularyReservation)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedFormularyReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedFormularyReservationStore: BatchedFormularyReservationStore {
        var items: [String: BatchedFormularyReservation]
        var order: [String]

        init(items: [String: BatchedFormularyReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedFormularyReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedFormularyReservation) {
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

        func list() -> [BatchedFormularyReservation] {
            var out: [BatchedFormularyReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedFormularyReservationStore() -> any BatchedFormularyReservationStore {
        return MemoryBatchedFormularyReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedFormularyReservationStore: BatchedFormularyReservationStore {
        var inner: MemoryBatchedFormularyReservationStore
        var cache: TTLCache<BatchedFormularyReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedFormularyReservationStore, cache: TTLCache<BatchedFormularyReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedFormularyReservation? {
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

        func save(_ item: BatchedFormularyReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedFormularyReservation] {
            return inner.list()
        }
    }

    static func newCachedBatchedFormularyReservationStore(_ inner: MemoryBatchedFormularyReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedFormularyReservationStore {
        return CachedBatchedFormularyReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched formulary reservations. Empty fields match all.
    final class BatchedFormularyReservationQuery {
        var segment: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedFormularyReservation) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [BatchedFormularyReservation]) -> [BatchedFormularyReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedFormularyReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedFormularyReservations(_ store: any BatchedFormularyReservationStore, query: BatchedFormularyReservationQuery) -> [BatchedFormularyReservation] {
        return query.apply(store.list())
    }
}
