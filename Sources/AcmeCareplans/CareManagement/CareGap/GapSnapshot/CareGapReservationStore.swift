import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap reservations by code.
    protocol CareGapReservationStore {
        func find(_ code: String) -> CareGapReservation?
        func save(_ item: CareGapReservation)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapReservationStore: CareGapReservationStore {
        var items: [String: CareGapReservation]
        var order: [String]

        init(items: [String: CareGapReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapReservation) {
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

        func list() -> [CareGapReservation] {
            var out: [CareGapReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapReservationStore() -> any CareGapReservationStore {
        return MemoryCareGapReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapReservationStore: CareGapReservationStore {
        var inner: MemoryCareGapReservationStore
        var cache: TTLCache<CareGapReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapReservationStore, cache: TTLCache<CareGapReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapReservation? {
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

        func save(_ item: CareGapReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapReservation] {
            return inner.list()
        }
    }

    static func newCachedCareGapReservationStore(_ inner: MemoryCareGapReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapReservationStore {
        return CachedCareGapReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap reservations. Empty fields match all.
    final class CareGapReservationQuery {
        var unit: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapReservation) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [CareGapReservation]) -> [CareGapReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapReservations(_ store: any CareGapReservationStore, query: CareGapReservationQuery) -> [CareGapReservation] {
        return query.apply(store.list())
    }
}
