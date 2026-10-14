import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall reservations by code.
    protocol RecallReservationStore {
        func find(_ code: String) -> RecallReservation?
        func save(_ item: RecallReservation)
        func remove(_ code: String) -> Bool
        func list() -> [RecallReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallReservationStore: RecallReservationStore {
        var items: [String: RecallReservation]
        var order: [String]

        init(items: [String: RecallReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallReservation) {
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

        func list() -> [RecallReservation] {
            var out: [RecallReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallReservationStore() -> any RecallReservationStore {
        return MemoryRecallReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallReservationStore: RecallReservationStore {
        var inner: MemoryRecallReservationStore
        var cache: TTLCache<RecallReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallReservationStore, cache: TTLCache<RecallReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallReservation? {
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

        func save(_ item: RecallReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallReservation] {
            return inner.list()
        }
    }

    static func newCachedRecallReservationStore(_ inner: MemoryRecallReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallReservationStore {
        return CachedRecallReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall reservations. Empty fields match all.
    final class RecallReservationQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallReservation) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [RecallReservation]) -> [RecallReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallReservations(_ store: any RecallReservationStore, query: RecallReservationQuery) -> [RecallReservation] {
        return query.apply(store.list())
    }
}
