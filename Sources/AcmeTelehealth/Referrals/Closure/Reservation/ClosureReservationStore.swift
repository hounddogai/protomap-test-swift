import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure reservations by code.
    protocol ClosureReservationStore {
        func find(_ code: String) -> ClosureReservation?
        func save(_ item: ClosureReservation)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureReservationStore: ClosureReservationStore {
        var items: [String: ClosureReservation]
        var order: [String]

        init(items: [String: ClosureReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureReservation) {
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

        func list() -> [ClosureReservation] {
            var out: [ClosureReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureReservationStore() -> any ClosureReservationStore {
        return MemoryClosureReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureReservationStore: ClosureReservationStore {
        var inner: MemoryClosureReservationStore
        var cache: TTLCache<ClosureReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureReservationStore, cache: TTLCache<ClosureReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureReservation? {
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

        func save(_ item: ClosureReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureReservation] {
            return inner.list()
        }
    }

    static func newCachedClosureReservationStore(_ inner: MemoryClosureReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureReservationStore {
        return CachedClosureReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure reservations. Empty fields match all.
    final class ClosureReservationQuery {
        var name: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRevision: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureReservation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureReservation]) -> [ClosureReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureReservations(_ store: any ClosureReservationStore, query: ClosureReservationQuery) -> [ClosureReservation] {
        return query.apply(store.list())
    }
}
