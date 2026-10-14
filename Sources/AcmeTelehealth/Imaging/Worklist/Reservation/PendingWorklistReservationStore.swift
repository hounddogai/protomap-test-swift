import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending worklist reservations by code.
    protocol PendingWorklistReservationStore {
        func find(_ code: String) -> PendingWorklistReservation?
        func save(_ item: PendingWorklistReservation)
        func remove(_ code: String) -> Bool
        func list() -> [PendingWorklistReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingWorklistReservationStore: PendingWorklistReservationStore {
        var items: [String: PendingWorklistReservation]
        var order: [String]

        init(items: [String: PendingWorklistReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingWorklistReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingWorklistReservation) {
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

        func list() -> [PendingWorklistReservation] {
            var out: [PendingWorklistReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingWorklistReservationStore() -> any PendingWorklistReservationStore {
        return MemoryPendingWorklistReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingWorklistReservationStore: PendingWorklistReservationStore {
        var inner: MemoryPendingWorklistReservationStore
        var cache: TTLCache<PendingWorklistReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingWorklistReservationStore, cache: TTLCache<PendingWorklistReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingWorklistReservation? {
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

        func save(_ item: PendingWorklistReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingWorklistReservation] {
            return inner.list()
        }
    }

    static func newCachedPendingWorklistReservationStore(_ inner: MemoryPendingWorklistReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingWorklistReservationStore {
        return CachedPendingWorklistReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending worklist reservations. Empty fields match all.
    final class PendingWorklistReservationQuery {
        var title: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingWorklistReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [PendingWorklistReservation]) -> [PendingWorklistReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingWorklistReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingWorklistReservations(_ store: any PendingWorklistReservationStore, query: PendingWorklistReservationQuery) -> [PendingWorklistReservation] {
        return query.apply(store.list())
    }
}
