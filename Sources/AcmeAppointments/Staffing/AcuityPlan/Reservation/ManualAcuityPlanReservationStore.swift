import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps manual acuity plan reservations by code.
    protocol ManualAcuityPlanReservationStore {
        func find(_ code: String) -> ManualAcuityPlanReservation?
        func save(_ item: ManualAcuityPlanReservation)
        func remove(_ code: String) -> Bool
        func list() -> [ManualAcuityPlanReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualAcuityPlanReservationStore: ManualAcuityPlanReservationStore {
        var items: [String: ManualAcuityPlanReservation]
        var order: [String]

        init(items: [String: ManualAcuityPlanReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualAcuityPlanReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualAcuityPlanReservation) {
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

        func list() -> [ManualAcuityPlanReservation] {
            var out: [ManualAcuityPlanReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualAcuityPlanReservationStore() -> any ManualAcuityPlanReservationStore {
        return MemoryManualAcuityPlanReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualAcuityPlanReservationStore: ManualAcuityPlanReservationStore {
        var inner: MemoryManualAcuityPlanReservationStore
        var cache: TTLCache<ManualAcuityPlanReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualAcuityPlanReservationStore, cache: TTLCache<ManualAcuityPlanReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualAcuityPlanReservation? {
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

        func save(_ item: ManualAcuityPlanReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualAcuityPlanReservation] {
            return inner.list()
        }
    }

    static func newCachedManualAcuityPlanReservationStore(_ inner: MemoryManualAcuityPlanReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualAcuityPlanReservationStore {
        return CachedManualAcuityPlanReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual acuity plan reservations. Empty fields match all.
    final class ManualAcuityPlanReservationQuery {
        var category: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualAcuityPlanReservation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [ManualAcuityPlanReservation]) -> [ManualAcuityPlanReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualAcuityPlanReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualAcuityPlanReservations(_ store: any ManualAcuityPlanReservationStore, query: ManualAcuityPlanReservationQuery) -> [ManualAcuityPlanReservation] {
        return query.apply(store.list())
    }
}
