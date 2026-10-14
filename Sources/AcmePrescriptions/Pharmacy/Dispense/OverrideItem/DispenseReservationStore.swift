import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense reservations by code.
    protocol DispenseReservationStore {
        func find(_ code: String) -> DispenseReservation?
        func save(_ item: DispenseReservation)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseReservationStore: DispenseReservationStore {
        var items: [String: DispenseReservation]
        var order: [String]

        init(items: [String: DispenseReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseReservation) {
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

        func list() -> [DispenseReservation] {
            var out: [DispenseReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseReservationStore() -> any DispenseReservationStore {
        return MemoryDispenseReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseReservationStore: DispenseReservationStore {
        var inner: MemoryDispenseReservationStore
        var cache: TTLCache<DispenseReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseReservationStore, cache: TTLCache<DispenseReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseReservation? {
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

        func save(_ item: DispenseReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseReservation] {
            return inner.list()
        }
    }

    static func newCachedDispenseReservationStore(_ inner: MemoryDispenseReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseReservationStore {
        return CachedDispenseReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense reservations. Empty fields match all.
    final class DispenseReservationQuery {
        var unit: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minPriority: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseReservation) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseReservation]) -> [DispenseReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseReservations(_ store: any DispenseReservationStore, query: DispenseReservationQuery) -> [DispenseReservation] {
        return query.apply(store.list())
    }
}
