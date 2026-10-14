import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling accession reservations by code.
    protocol RollingAccessionReservationStore {
        func find(_ code: String) -> RollingAccessionReservation?
        func save(_ item: RollingAccessionReservation)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAccessionReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAccessionReservationStore: RollingAccessionReservationStore {
        var items: [String: RollingAccessionReservation]
        var order: [String]

        init(items: [String: RollingAccessionReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAccessionReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAccessionReservation) {
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

        func list() -> [RollingAccessionReservation] {
            var out: [RollingAccessionReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAccessionReservationStore() -> any RollingAccessionReservationStore {
        return MemoryRollingAccessionReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAccessionReservationStore: RollingAccessionReservationStore {
        var inner: MemoryRollingAccessionReservationStore
        var cache: TTLCache<RollingAccessionReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAccessionReservationStore, cache: TTLCache<RollingAccessionReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAccessionReservation? {
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

        func save(_ item: RollingAccessionReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAccessionReservation] {
            return inner.list()
        }
    }

    static func newCachedRollingAccessionReservationStore(_ inner: MemoryRollingAccessionReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAccessionReservationStore {
        return CachedRollingAccessionReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling accession reservations. Empty fields match all.
    final class RollingAccessionReservationQuery {
        var unit: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingAccessionReservation) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [RollingAccessionReservation]) -> [RollingAccessionReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAccessionReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAccessionReservations(_ store: any RollingAccessionReservationStore, query: RollingAccessionReservationQuery) -> [RollingAccessionReservation] {
        return query.apply(store.list())
    }
}
