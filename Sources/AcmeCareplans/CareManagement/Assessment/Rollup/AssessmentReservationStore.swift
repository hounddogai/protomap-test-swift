import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment reservations by code.
    protocol AssessmentReservationStore {
        func find(_ code: String) -> AssessmentReservation?
        func save(_ item: AssessmentReservation)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentReservationStore: AssessmentReservationStore {
        var items: [String: AssessmentReservation]
        var order: [String]

        init(items: [String: AssessmentReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentReservation) {
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

        func list() -> [AssessmentReservation] {
            var out: [AssessmentReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentReservationStore() -> any AssessmentReservationStore {
        return MemoryAssessmentReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentReservationStore: AssessmentReservationStore {
        var inner: MemoryAssessmentReservationStore
        var cache: TTLCache<AssessmentReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentReservationStore, cache: TTLCache<AssessmentReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentReservation? {
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

        func save(_ item: AssessmentReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentReservation] {
            return inner.list()
        }
    }

    static func newCachedAssessmentReservationStore(_ inner: MemoryAssessmentReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentReservationStore {
        return CachedAssessmentReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment reservations. Empty fields match all.
    final class AssessmentReservationQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentReservation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentReservation]) -> [AssessmentReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentReservations(_ store: any AssessmentReservationStore, query: AssessmentReservationQuery) -> [AssessmentReservation] {
        return query.apply(store.list())
    }
}
