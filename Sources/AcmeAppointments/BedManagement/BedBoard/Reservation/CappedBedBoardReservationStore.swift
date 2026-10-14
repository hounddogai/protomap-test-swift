import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped bed board reservations by code.
    protocol CappedBedBoardReservationStore {
        func find(_ code: String) -> CappedBedBoardReservation?
        func save(_ item: CappedBedBoardReservation)
        func remove(_ code: String) -> Bool
        func list() -> [CappedBedBoardReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedBedBoardReservationStore: CappedBedBoardReservationStore {
        var items: [String: CappedBedBoardReservation]
        var order: [String]

        init(items: [String: CappedBedBoardReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedBedBoardReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedBedBoardReservation) {
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

        func list() -> [CappedBedBoardReservation] {
            var out: [CappedBedBoardReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedBedBoardReservationStore() -> any CappedBedBoardReservationStore {
        return MemoryCappedBedBoardReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedBedBoardReservationStore: CappedBedBoardReservationStore {
        var inner: MemoryCappedBedBoardReservationStore
        var cache: TTLCache<CappedBedBoardReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedBedBoardReservationStore, cache: TTLCache<CappedBedBoardReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedBedBoardReservation? {
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

        func save(_ item: CappedBedBoardReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedBedBoardReservation] {
            return inner.list()
        }
    }

    static func newCachedCappedBedBoardReservationStore(_ inner: MemoryCappedBedBoardReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedBedBoardReservationStore {
        return CachedCappedBedBoardReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped bed board reservations. Empty fields match all.
    final class CappedBedBoardReservationQuery {
        var country: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedBedBoardReservation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedBedBoardReservation]) -> [CappedBedBoardReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedBedBoardReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedBedBoardReservations(_ store: any CappedBedBoardReservationStore, query: CappedBedBoardReservationQuery) -> [CappedBedBoardReservation] {
        return query.apply(store.list())
    }
}
