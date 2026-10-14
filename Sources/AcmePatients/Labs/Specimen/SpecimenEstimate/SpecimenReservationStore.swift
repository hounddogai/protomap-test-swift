import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen reservations by code.
    protocol SpecimenReservationStore {
        func find(_ code: String) -> SpecimenReservation?
        func save(_ item: SpecimenReservation)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenReservationStore: SpecimenReservationStore {
        var items: [String: SpecimenReservation]
        var order: [String]

        init(items: [String: SpecimenReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenReservation) {
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

        func list() -> [SpecimenReservation] {
            var out: [SpecimenReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenReservationStore() -> any SpecimenReservationStore {
        return MemorySpecimenReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenReservationStore: SpecimenReservationStore {
        var inner: MemorySpecimenReservationStore
        var cache: TTLCache<SpecimenReservation>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenReservationStore, cache: TTLCache<SpecimenReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenReservation? {
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

        func save(_ item: SpecimenReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenReservation] {
            return inner.list()
        }
    }

    static func newCachedSpecimenReservationStore(_ inner: MemorySpecimenReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenReservationStore {
        return CachedSpecimenReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen reservations. Empty fields match all.
    final class SpecimenReservationQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenReservation]) -> [SpecimenReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenReservations(_ store: any SpecimenReservationStore, query: SpecimenReservationQuery) -> [SpecimenReservation] {
        return query.apply(store.list())
    }
}
