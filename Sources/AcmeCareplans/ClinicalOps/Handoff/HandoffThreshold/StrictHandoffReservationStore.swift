import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict handoff reservations by code.
    protocol StrictHandoffReservationStore {
        func find(_ code: String) -> StrictHandoffReservation?
        func save(_ item: StrictHandoffReservation)
        func remove(_ code: String) -> Bool
        func list() -> [StrictHandoffReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictHandoffReservationStore: StrictHandoffReservationStore {
        var items: [String: StrictHandoffReservation]
        var order: [String]

        init(items: [String: StrictHandoffReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictHandoffReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictHandoffReservation) {
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

        func list() -> [StrictHandoffReservation] {
            var out: [StrictHandoffReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictHandoffReservationStore() -> any StrictHandoffReservationStore {
        return MemoryStrictHandoffReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictHandoffReservationStore: StrictHandoffReservationStore {
        var inner: MemoryStrictHandoffReservationStore
        var cache: TTLCache<StrictHandoffReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictHandoffReservationStore, cache: TTLCache<StrictHandoffReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictHandoffReservation? {
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

        func save(_ item: StrictHandoffReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictHandoffReservation] {
            return inner.list()
        }
    }

    static func newCachedStrictHandoffReservationStore(_ inner: MemoryStrictHandoffReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictHandoffReservationStore {
        return CachedStrictHandoffReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict handoff reservations. Empty fields match all.
    final class StrictHandoffReservationQuery {
        var country: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictHandoffReservation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictHandoffReservation]) -> [StrictHandoffReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictHandoffReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictHandoffReservations(_ store: any StrictHandoffReservationStore, query: StrictHandoffReservationQuery) -> [StrictHandoffReservation] {
        return query.apply(store.list())
    }
}
