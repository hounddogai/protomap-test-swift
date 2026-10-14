import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set reservations by code.
    protocol OrderSetReservationStore {
        func find(_ code: String) -> OrderSetReservation?
        func save(_ item: OrderSetReservation)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetReservationStore: OrderSetReservationStore {
        var items: [String: OrderSetReservation]
        var order: [String]

        init(items: [String: OrderSetReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetReservation) {
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

        func list() -> [OrderSetReservation] {
            var out: [OrderSetReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetReservationStore() -> any OrderSetReservationStore {
        return MemoryOrderSetReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetReservationStore: OrderSetReservationStore {
        var inner: MemoryOrderSetReservationStore
        var cache: TTLCache<OrderSetReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetReservationStore, cache: TTLCache<OrderSetReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetReservation? {
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

        func save(_ item: OrderSetReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetReservation] {
            return inner.list()
        }
    }

    static func newCachedOrderSetReservationStore(_ inner: MemoryOrderSetReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetReservationStore {
        return CachedOrderSetReservationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set reservations. Empty fields match all.
    final class OrderSetReservationQuery {
        var source: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRatio: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetReservation) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetReservation]) -> [OrderSetReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetReservations(_ store: any OrderSetReservationStore, query: OrderSetReservationQuery) -> [OrderSetReservation] {
        return query.apply(store.list())
    }
}
