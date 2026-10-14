import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional result reservations by code.
    protocol RegionalResultReservationStore {
        func find(_ code: String) -> RegionalResultReservation?
        func save(_ item: RegionalResultReservation)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalResultReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalResultReservationStore: RegionalResultReservationStore {
        var items: [String: RegionalResultReservation]
        var order: [String]

        init(items: [String: RegionalResultReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalResultReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalResultReservation) {
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

        func list() -> [RegionalResultReservation] {
            var out: [RegionalResultReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalResultReservationStore() -> any RegionalResultReservationStore {
        return MemoryRegionalResultReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalResultReservationStore: RegionalResultReservationStore {
        var inner: MemoryRegionalResultReservationStore
        var cache: TTLCache<RegionalResultReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalResultReservationStore, cache: TTLCache<RegionalResultReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalResultReservation? {
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

        func save(_ item: RegionalResultReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalResultReservation] {
            return inner.list()
        }
    }

    static func newCachedRegionalResultReservationStore(_ inner: MemoryRegionalResultReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalResultReservationStore {
        return CachedRegionalResultReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional result reservations. Empty fields match all.
    final class RegionalResultReservationQuery {
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

        func matches(_ item: RegionalResultReservation) -> Bool {
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

        func apply(_ items: [RegionalResultReservation]) -> [RegionalResultReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalResultReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalResultReservations(_ store: any RegionalResultReservationStore, query: RegionalResultReservationQuery) -> [RegionalResultReservation] {
        return query.apply(store.list())
    }
}
