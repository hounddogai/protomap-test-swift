import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning reservations by code.
    protocol CleaningReservationStore {
        func find(_ code: String) -> CleaningReservation?
        func save(_ item: CleaningReservation)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningReservationStore: CleaningReservationStore {
        var items: [String: CleaningReservation]
        var order: [String]

        init(items: [String: CleaningReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningReservation) {
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

        func list() -> [CleaningReservation] {
            var out: [CleaningReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningReservationStore() -> any CleaningReservationStore {
        return MemoryCleaningReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningReservationStore: CleaningReservationStore {
        var inner: MemoryCleaningReservationStore
        var cache: TTLCache<CleaningReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningReservationStore, cache: TTLCache<CleaningReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningReservation? {
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

        func save(_ item: CleaningReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningReservation] {
            return inner.list()
        }
    }

    static func newCachedCleaningReservationStore(_ inner: MemoryCleaningReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningReservationStore {
        return CachedCleaningReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning reservations. Empty fields match all.
    final class CleaningReservationQuery {
        var unit: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRetries: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningReservation) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningReservation]) -> [CleaningReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningReservations(_ store: any CleaningReservationStore, query: CleaningReservationQuery) -> [CleaningReservation] {
        return query.apply(store.list())
    }
}
