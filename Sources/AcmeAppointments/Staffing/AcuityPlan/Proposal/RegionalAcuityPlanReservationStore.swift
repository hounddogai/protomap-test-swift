import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional acuity plan reservations by code.
    protocol RegionalAcuityPlanReservationStore {
        func find(_ code: String) -> RegionalAcuityPlanReservation?
        func save(_ item: RegionalAcuityPlanReservation)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalAcuityPlanReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalAcuityPlanReservationStore: RegionalAcuityPlanReservationStore {
        var items: [String: RegionalAcuityPlanReservation]
        var order: [String]

        init(items: [String: RegionalAcuityPlanReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalAcuityPlanReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalAcuityPlanReservation) {
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

        func list() -> [RegionalAcuityPlanReservation] {
            var out: [RegionalAcuityPlanReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalAcuityPlanReservationStore() -> any RegionalAcuityPlanReservationStore {
        return MemoryRegionalAcuityPlanReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalAcuityPlanReservationStore: RegionalAcuityPlanReservationStore {
        var inner: MemoryRegionalAcuityPlanReservationStore
        var cache: TTLCache<RegionalAcuityPlanReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalAcuityPlanReservationStore, cache: TTLCache<RegionalAcuityPlanReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalAcuityPlanReservation? {
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

        func save(_ item: RegionalAcuityPlanReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalAcuityPlanReservation] {
            return inner.list()
        }
    }

    static func newCachedRegionalAcuityPlanReservationStore(_ inner: MemoryRegionalAcuityPlanReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalAcuityPlanReservationStore {
        return CachedRegionalAcuityPlanReservationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional acuity plan reservations. Empty fields match all.
    final class RegionalAcuityPlanReservationQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalAcuityPlanReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalAcuityPlanReservation]) -> [RegionalAcuityPlanReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalAcuityPlanReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalAcuityPlanReservations(_ store: any RegionalAcuityPlanReservationStore, query: RegionalAcuityPlanReservationQuery) -> [RegionalAcuityPlanReservation] {
        return query.apply(store.list())
    }
}
