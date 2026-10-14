import AcmePlatform
import Foundation

extension Consent {
    /// Keeps seasonal revocation reservations by code.
    protocol SeasonalRevocationReservationStore {
        func find(_ code: String) -> SeasonalRevocationReservation?
        func save(_ item: SeasonalRevocationReservation)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalRevocationReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalRevocationReservationStore: SeasonalRevocationReservationStore {
        var items: [String: SeasonalRevocationReservation]
        var order: [String]

        init(items: [String: SeasonalRevocationReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalRevocationReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalRevocationReservation) {
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

        func list() -> [SeasonalRevocationReservation] {
            var out: [SeasonalRevocationReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalRevocationReservationStore() -> any SeasonalRevocationReservationStore {
        return MemorySeasonalRevocationReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalRevocationReservationStore: SeasonalRevocationReservationStore {
        var inner: MemorySeasonalRevocationReservationStore
        var cache: TTLCache<SeasonalRevocationReservation>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalRevocationReservationStore, cache: TTLCache<SeasonalRevocationReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalRevocationReservation? {
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

        func save(_ item: SeasonalRevocationReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalRevocationReservation] {
            return inner.list()
        }
    }

    static func newCachedSeasonalRevocationReservationStore(_ inner: MemorySeasonalRevocationReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalRevocationReservationStore {
        return CachedSeasonalRevocationReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal revocation reservations. Empty fields match all.
    final class SeasonalRevocationReservationQuery {
        var facility: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCost: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalRevocationReservation) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalRevocationReservation]) -> [SeasonalRevocationReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalRevocationReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalRevocationReservations(_ store: any SeasonalRevocationReservationStore, query: SeasonalRevocationReservationQuery) -> [SeasonalRevocationReservation] {
        return query.apply(store.list())
    }
}
