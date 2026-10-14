import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary read reservations by code.
    protocol PrimaryReadReservationStore {
        func find(_ code: String) -> PrimaryReadReservation?
        func save(_ item: PrimaryReadReservation)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryReadReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryReadReservationStore: PrimaryReadReservationStore {
        var items: [String: PrimaryReadReservation]
        var order: [String]

        init(items: [String: PrimaryReadReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryReadReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryReadReservation) {
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

        func list() -> [PrimaryReadReservation] {
            var out: [PrimaryReadReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryReadReservationStore() -> any PrimaryReadReservationStore {
        return MemoryPrimaryReadReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryReadReservationStore: PrimaryReadReservationStore {
        var inner: MemoryPrimaryReadReservationStore
        var cache: TTLCache<PrimaryReadReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryReadReservationStore, cache: TTLCache<PrimaryReadReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryReadReservation? {
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

        func save(_ item: PrimaryReadReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryReadReservation] {
            return inner.list()
        }
    }

    static func newCachedPrimaryReadReservationStore(_ inner: MemoryPrimaryReadReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryReadReservationStore {
        return CachedPrimaryReadReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary read reservations. Empty fields match all.
    final class PrimaryReadReservationQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryReadReservation) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryReadReservation]) -> [PrimaryReadReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryReadReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryReadReservations(_ store: any PrimaryReadReservationStore, query: PrimaryReadReservationQuery) -> [PrimaryReadReservation] {
        return query.apply(store.list())
    }
}
