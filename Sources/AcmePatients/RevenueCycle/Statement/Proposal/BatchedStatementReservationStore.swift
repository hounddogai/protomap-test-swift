import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched statement reservations by code.
    protocol BatchedStatementReservationStore {
        func find(_ code: String) -> BatchedStatementReservation?
        func save(_ item: BatchedStatementReservation)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedStatementReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedStatementReservationStore: BatchedStatementReservationStore {
        var items: [String: BatchedStatementReservation]
        var order: [String]

        init(items: [String: BatchedStatementReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedStatementReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedStatementReservation) {
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

        func list() -> [BatchedStatementReservation] {
            var out: [BatchedStatementReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedStatementReservationStore() -> any BatchedStatementReservationStore {
        return MemoryBatchedStatementReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedStatementReservationStore: BatchedStatementReservationStore {
        var inner: MemoryBatchedStatementReservationStore
        var cache: TTLCache<BatchedStatementReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedStatementReservationStore, cache: TTLCache<BatchedStatementReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedStatementReservation? {
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

        func save(_ item: BatchedStatementReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedStatementReservation] {
            return inner.list()
        }
    }

    static func newCachedBatchedStatementReservationStore(_ inner: MemoryBatchedStatementReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedStatementReservationStore {
        return CachedBatchedStatementReservationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched statement reservations. Empty fields match all.
    final class BatchedStatementReservationQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedStatementReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [BatchedStatementReservation]) -> [BatchedStatementReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedStatementReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedStatementReservations(_ store: any BatchedStatementReservationStore, query: BatchedStatementReservationQuery) -> [BatchedStatementReservation] {
        return query.apply(store.list())
    }
}
