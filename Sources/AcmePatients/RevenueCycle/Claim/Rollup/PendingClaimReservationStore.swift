import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending claim reservations by code.
    protocol PendingClaimReservationStore {
        func find(_ code: String) -> PendingClaimReservation?
        func save(_ item: PendingClaimReservation)
        func remove(_ code: String) -> Bool
        func list() -> [PendingClaimReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingClaimReservationStore: PendingClaimReservationStore {
        var items: [String: PendingClaimReservation]
        var order: [String]

        init(items: [String: PendingClaimReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingClaimReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingClaimReservation) {
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

        func list() -> [PendingClaimReservation] {
            var out: [PendingClaimReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingClaimReservationStore() -> any PendingClaimReservationStore {
        return MemoryPendingClaimReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingClaimReservationStore: PendingClaimReservationStore {
        var inner: MemoryPendingClaimReservationStore
        var cache: TTLCache<PendingClaimReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingClaimReservationStore, cache: TTLCache<PendingClaimReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingClaimReservation? {
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

        func save(_ item: PendingClaimReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingClaimReservation] {
            return inner.list()
        }
    }

    static func newCachedPendingClaimReservationStore(_ inner: MemoryPendingClaimReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingClaimReservationStore {
        return CachedPendingClaimReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending claim reservations. Empty fields match all.
    final class PendingClaimReservationQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingClaimReservation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingClaimReservation]) -> [PendingClaimReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingClaimReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingClaimReservations(_ store: any PendingClaimReservationStore, query: PendingClaimReservationQuery) -> [PendingClaimReservation] {
        return query.apply(store.list())
    }
}
