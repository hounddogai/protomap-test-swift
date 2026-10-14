import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling assessment reservations by code.
    protocol RollingAssessmentReservationStore {
        func find(_ code: String) -> RollingAssessmentReservation?
        func save(_ item: RollingAssessmentReservation)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAssessmentReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAssessmentReservationStore: RollingAssessmentReservationStore {
        var items: [String: RollingAssessmentReservation]
        var order: [String]

        init(items: [String: RollingAssessmentReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAssessmentReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAssessmentReservation) {
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

        func list() -> [RollingAssessmentReservation] {
            var out: [RollingAssessmentReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAssessmentReservationStore() -> any RollingAssessmentReservationStore {
        return MemoryRollingAssessmentReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAssessmentReservationStore: RollingAssessmentReservationStore {
        var inner: MemoryRollingAssessmentReservationStore
        var cache: TTLCache<RollingAssessmentReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAssessmentReservationStore, cache: TTLCache<RollingAssessmentReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAssessmentReservation? {
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

        func save(_ item: RollingAssessmentReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAssessmentReservation] {
            return inner.list()
        }
    }

    static func newCachedRollingAssessmentReservationStore(_ inner: MemoryRollingAssessmentReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAssessmentReservationStore {
        return CachedRollingAssessmentReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling assessment reservations. Empty fields match all.
    final class RollingAssessmentReservationQuery {
        var category: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minAmount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingAssessmentReservation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [RollingAssessmentReservation]) -> [RollingAssessmentReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAssessmentReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAssessmentReservations(_ store: any RollingAssessmentReservationStore, query: RollingAssessmentReservationQuery) -> [RollingAssessmentReservation] {
        return query.apply(store.list())
    }
}
