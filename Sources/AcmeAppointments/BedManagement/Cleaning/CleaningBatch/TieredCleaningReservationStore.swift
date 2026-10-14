import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps tiered cleaning reservations by code.
    protocol TieredCleaningReservationStore {
        func find(_ code: String) -> TieredCleaningReservation?
        func save(_ item: TieredCleaningReservation)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCleaningReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCleaningReservationStore: TieredCleaningReservationStore {
        var items: [String: TieredCleaningReservation]
        var order: [String]

        init(items: [String: TieredCleaningReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCleaningReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCleaningReservation) {
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

        func list() -> [TieredCleaningReservation] {
            var out: [TieredCleaningReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCleaningReservationStore() -> any TieredCleaningReservationStore {
        return MemoryTieredCleaningReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCleaningReservationStore: TieredCleaningReservationStore {
        var inner: MemoryTieredCleaningReservationStore
        var cache: TTLCache<TieredCleaningReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCleaningReservationStore, cache: TTLCache<TieredCleaningReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCleaningReservation? {
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

        func save(_ item: TieredCleaningReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCleaningReservation] {
            return inner.list()
        }
    }

    static func newCachedTieredCleaningReservationStore(_ inner: MemoryTieredCleaningReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCleaningReservationStore {
        return CachedTieredCleaningReservationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered cleaning reservations. Empty fields match all.
    final class TieredCleaningReservationQuery {
        var country: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredCleaningReservation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredCleaningReservation]) -> [TieredCleaningReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCleaningReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCleaningReservations(_ store: any TieredCleaningReservationStore, query: TieredCleaningReservationQuery) -> [TieredCleaningReservation] {
        return query.apply(store.list())
    }
}
