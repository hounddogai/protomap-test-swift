import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending follow up reservations by code.
    protocol PendingFollowUpReservationStore {
        func find(_ code: String) -> PendingFollowUpReservation?
        func save(_ item: PendingFollowUpReservation)
        func remove(_ code: String) -> Bool
        func list() -> [PendingFollowUpReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingFollowUpReservationStore: PendingFollowUpReservationStore {
        var items: [String: PendingFollowUpReservation]
        var order: [String]

        init(items: [String: PendingFollowUpReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingFollowUpReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingFollowUpReservation) {
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

        func list() -> [PendingFollowUpReservation] {
            var out: [PendingFollowUpReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingFollowUpReservationStore() -> any PendingFollowUpReservationStore {
        return MemoryPendingFollowUpReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingFollowUpReservationStore: PendingFollowUpReservationStore {
        var inner: MemoryPendingFollowUpReservationStore
        var cache: TTLCache<PendingFollowUpReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingFollowUpReservationStore, cache: TTLCache<PendingFollowUpReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingFollowUpReservation? {
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

        func save(_ item: PendingFollowUpReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingFollowUpReservation] {
            return inner.list()
        }
    }

    static func newCachedPendingFollowUpReservationStore(_ inner: MemoryPendingFollowUpReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingFollowUpReservationStore {
        return CachedPendingFollowUpReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending follow up reservations. Empty fields match all.
    final class PendingFollowUpReservationQuery {
        var facility: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingFollowUpReservation) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [PendingFollowUpReservation]) -> [PendingFollowUpReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingFollowUpReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingFollowUpReservations(_ store: any PendingFollowUpReservationStore, query: PendingFollowUpReservationQuery) -> [PendingFollowUpReservation] {
        return query.apply(store.list())
    }
}
