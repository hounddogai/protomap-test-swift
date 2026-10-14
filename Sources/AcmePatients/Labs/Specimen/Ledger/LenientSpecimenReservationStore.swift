import AcmePlatform
import Foundation

extension Labs {
    /// Keeps lenient specimen reservations by code.
    protocol LenientSpecimenReservationStore {
        func find(_ code: String) -> LenientSpecimenReservation?
        func save(_ item: LenientSpecimenReservation)
        func remove(_ code: String) -> Bool
        func list() -> [LenientSpecimenReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientSpecimenReservationStore: LenientSpecimenReservationStore {
        var items: [String: LenientSpecimenReservation]
        var order: [String]

        init(items: [String: LenientSpecimenReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientSpecimenReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientSpecimenReservation) {
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

        func list() -> [LenientSpecimenReservation] {
            var out: [LenientSpecimenReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientSpecimenReservationStore() -> any LenientSpecimenReservationStore {
        return MemoryLenientSpecimenReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientSpecimenReservationStore: LenientSpecimenReservationStore {
        var inner: MemoryLenientSpecimenReservationStore
        var cache: TTLCache<LenientSpecimenReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientSpecimenReservationStore, cache: TTLCache<LenientSpecimenReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientSpecimenReservation? {
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

        func save(_ item: LenientSpecimenReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientSpecimenReservation] {
            return inner.list()
        }
    }

    static func newCachedLenientSpecimenReservationStore(_ inner: MemoryLenientSpecimenReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientSpecimenReservationStore {
        return CachedLenientSpecimenReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient specimen reservations. Empty fields match all.
    final class LenientSpecimenReservationQuery {
        var region: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minSequence: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientSpecimenReservation) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientSpecimenReservation]) -> [LenientSpecimenReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientSpecimenReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientSpecimenReservations(_ store: any LenientSpecimenReservationStore, query: LenientSpecimenReservationQuery) -> [LenientSpecimenReservation] {
        return query.apply(store.list())
    }
}
