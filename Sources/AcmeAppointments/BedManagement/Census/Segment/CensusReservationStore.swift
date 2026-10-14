import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census reservations by code.
    protocol CensusReservationStore {
        func find(_ code: String) -> CensusReservation?
        func save(_ item: CensusReservation)
        func remove(_ code: String) -> Bool
        func list() -> [CensusReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusReservationStore: CensusReservationStore {
        var items: [String: CensusReservation]
        var order: [String]

        init(items: [String: CensusReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusReservation) {
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

        func list() -> [CensusReservation] {
            var out: [CensusReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusReservationStore() -> any CensusReservationStore {
        return MemoryCensusReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusReservationStore: CensusReservationStore {
        var inner: MemoryCensusReservationStore
        var cache: TTLCache<CensusReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusReservationStore, cache: TTLCache<CensusReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusReservation? {
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

        func save(_ item: CensusReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusReservation] {
            return inner.list()
        }
    }

    static func newCachedCensusReservationStore(_ inner: MemoryCensusReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusReservationStore {
        return CachedCensusReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census reservations. Empty fields match all.
    final class CensusReservationQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusReservation]) -> [CensusReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusReservations(_ store: any CensusReservationStore, query: CensusReservationQuery) -> [CensusReservation] {
        return query.apply(store.list())
    }
}
