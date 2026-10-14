import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default specimen reservations by code.
    protocol DefaultSpecimenReservationStore {
        func find(_ code: String) -> DefaultSpecimenReservation?
        func save(_ item: DefaultSpecimenReservation)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultSpecimenReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultSpecimenReservationStore: DefaultSpecimenReservationStore {
        var items: [String: DefaultSpecimenReservation]
        var order: [String]

        init(items: [String: DefaultSpecimenReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultSpecimenReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultSpecimenReservation) {
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

        func list() -> [DefaultSpecimenReservation] {
            var out: [DefaultSpecimenReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultSpecimenReservationStore() -> any DefaultSpecimenReservationStore {
        return MemoryDefaultSpecimenReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultSpecimenReservationStore: DefaultSpecimenReservationStore {
        var inner: MemoryDefaultSpecimenReservationStore
        var cache: TTLCache<DefaultSpecimenReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultSpecimenReservationStore, cache: TTLCache<DefaultSpecimenReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultSpecimenReservation? {
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

        func save(_ item: DefaultSpecimenReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultSpecimenReservation] {
            return inner.list()
        }
    }

    static func newCachedDefaultSpecimenReservationStore(_ inner: MemoryDefaultSpecimenReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultSpecimenReservationStore {
        return CachedDefaultSpecimenReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default specimen reservations. Empty fields match all.
    final class DefaultSpecimenReservationQuery {
        var locale: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultSpecimenReservation) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultSpecimenReservation]) -> [DefaultSpecimenReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultSpecimenReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultSpecimenReservations(_ store: any DefaultSpecimenReservationStore, query: DefaultSpecimenReservationQuery) -> [DefaultSpecimenReservation] {
        return query.apply(store.list())
    }
}
