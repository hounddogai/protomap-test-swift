import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending formulary reservations by code.
    protocol PendingFormularyReservationStore {
        func find(_ code: String) -> PendingFormularyReservation?
        func save(_ item: PendingFormularyReservation)
        func remove(_ code: String) -> Bool
        func list() -> [PendingFormularyReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingFormularyReservationStore: PendingFormularyReservationStore {
        var items: [String: PendingFormularyReservation]
        var order: [String]

        init(items: [String: PendingFormularyReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingFormularyReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingFormularyReservation) {
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

        func list() -> [PendingFormularyReservation] {
            var out: [PendingFormularyReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingFormularyReservationStore() -> any PendingFormularyReservationStore {
        return MemoryPendingFormularyReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingFormularyReservationStore: PendingFormularyReservationStore {
        var inner: MemoryPendingFormularyReservationStore
        var cache: TTLCache<PendingFormularyReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingFormularyReservationStore, cache: TTLCache<PendingFormularyReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingFormularyReservation? {
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

        func save(_ item: PendingFormularyReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingFormularyReservation] {
            return inner.list()
        }
    }

    static func newCachedPendingFormularyReservationStore(_ inner: MemoryPendingFormularyReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingFormularyReservationStore {
        return CachedPendingFormularyReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending formulary reservations. Empty fields match all.
    final class PendingFormularyReservationQuery {
        var unit: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minBudget: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingFormularyReservation) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingFormularyReservation]) -> [PendingFormularyReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingFormularyReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingFormularyReservations(_ store: any PendingFormularyReservationStore, query: PendingFormularyReservationQuery) -> [PendingFormularyReservation] {
        return query.apply(store.list())
    }
}
