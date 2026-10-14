import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps strict assessment reservations by code.
    protocol StrictAssessmentReservationStore {
        func find(_ code: String) -> StrictAssessmentReservation?
        func save(_ item: StrictAssessmentReservation)
        func remove(_ code: String) -> Bool
        func list() -> [StrictAssessmentReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictAssessmentReservationStore: StrictAssessmentReservationStore {
        var items: [String: StrictAssessmentReservation]
        var order: [String]

        init(items: [String: StrictAssessmentReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictAssessmentReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictAssessmentReservation) {
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

        func list() -> [StrictAssessmentReservation] {
            var out: [StrictAssessmentReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictAssessmentReservationStore() -> any StrictAssessmentReservationStore {
        return MemoryStrictAssessmentReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictAssessmentReservationStore: StrictAssessmentReservationStore {
        var inner: MemoryStrictAssessmentReservationStore
        var cache: TTLCache<StrictAssessmentReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictAssessmentReservationStore, cache: TTLCache<StrictAssessmentReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictAssessmentReservation? {
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

        func save(_ item: StrictAssessmentReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictAssessmentReservation] {
            return inner.list()
        }
    }

    static func newCachedStrictAssessmentReservationStore(_ inner: MemoryStrictAssessmentReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictAssessmentReservationStore {
        return CachedStrictAssessmentReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict assessment reservations. Empty fields match all.
    final class StrictAssessmentReservationQuery {
        var country: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minPriority: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictAssessmentReservation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [StrictAssessmentReservation]) -> [StrictAssessmentReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictAssessmentReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictAssessmentReservations(_ store: any StrictAssessmentReservationStore, query: StrictAssessmentReservationQuery) -> [StrictAssessmentReservation] {
        return query.apply(store.list())
    }
}
