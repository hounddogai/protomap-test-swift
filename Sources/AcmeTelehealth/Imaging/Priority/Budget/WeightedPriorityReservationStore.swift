import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps weighted priority reservations by code.
    protocol WeightedPriorityReservationStore {
        func find(_ code: String) -> WeightedPriorityReservation?
        func save(_ item: WeightedPriorityReservation)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedPriorityReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedPriorityReservationStore: WeightedPriorityReservationStore {
        var items: [String: WeightedPriorityReservation]
        var order: [String]

        init(items: [String: WeightedPriorityReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedPriorityReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedPriorityReservation) {
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

        func list() -> [WeightedPriorityReservation] {
            var out: [WeightedPriorityReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedPriorityReservationStore() -> any WeightedPriorityReservationStore {
        return MemoryWeightedPriorityReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedPriorityReservationStore: WeightedPriorityReservationStore {
        var inner: MemoryWeightedPriorityReservationStore
        var cache: TTLCache<WeightedPriorityReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedPriorityReservationStore, cache: TTLCache<WeightedPriorityReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedPriorityReservation? {
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

        func save(_ item: WeightedPriorityReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedPriorityReservation] {
            return inner.list()
        }
    }

    static func newCachedWeightedPriorityReservationStore(_ inner: MemoryWeightedPriorityReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedPriorityReservationStore {
        return CachedWeightedPriorityReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted priority reservations. Empty fields match all.
    final class WeightedPriorityReservationQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedPriorityReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [WeightedPriorityReservation]) -> [WeightedPriorityReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedPriorityReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedPriorityReservations(_ store: any WeightedPriorityReservationStore, query: WeightedPriorityReservationQuery) -> [WeightedPriorityReservation] {
        return query.apply(store.list())
    }
}
