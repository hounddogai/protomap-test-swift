import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan reservations by code.
    protocol AcuityPlanReservationStore {
        func find(_ code: String) -> AcuityPlanReservation?
        func save(_ item: AcuityPlanReservation)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanReservationStore: AcuityPlanReservationStore {
        var items: [String: AcuityPlanReservation]
        var order: [String]

        init(items: [String: AcuityPlanReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanReservation) {
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

        func list() -> [AcuityPlanReservation] {
            var out: [AcuityPlanReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanReservationStore() -> any AcuityPlanReservationStore {
        return MemoryAcuityPlanReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanReservationStore: AcuityPlanReservationStore {
        var inner: MemoryAcuityPlanReservationStore
        var cache: TTLCache<AcuityPlanReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanReservationStore, cache: TTLCache<AcuityPlanReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanReservation? {
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

        func save(_ item: AcuityPlanReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanReservation] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanReservationStore(_ inner: MemoryAcuityPlanReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanReservationStore {
        return CachedAcuityPlanReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan reservations. Empty fields match all.
    final class AcuityPlanReservationQuery {
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

        func matches(_ item: AcuityPlanReservation) -> Bool {
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

        func apply(_ items: [AcuityPlanReservation]) -> [AcuityPlanReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanReservations(_ store: any AcuityPlanReservationStore, query: AcuityPlanReservationQuery) -> [AcuityPlanReservation] {
        return query.apply(store.list())
    }
}
