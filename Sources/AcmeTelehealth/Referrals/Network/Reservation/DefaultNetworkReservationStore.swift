import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps default network reservations by code.
    protocol DefaultNetworkReservationStore {
        func find(_ code: String) -> DefaultNetworkReservation?
        func save(_ item: DefaultNetworkReservation)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultNetworkReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultNetworkReservationStore: DefaultNetworkReservationStore {
        var items: [String: DefaultNetworkReservation]
        var order: [String]

        init(items: [String: DefaultNetworkReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultNetworkReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultNetworkReservation) {
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

        func list() -> [DefaultNetworkReservation] {
            var out: [DefaultNetworkReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultNetworkReservationStore() -> any DefaultNetworkReservationStore {
        return MemoryDefaultNetworkReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultNetworkReservationStore: DefaultNetworkReservationStore {
        var inner: MemoryDefaultNetworkReservationStore
        var cache: TTLCache<DefaultNetworkReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultNetworkReservationStore, cache: TTLCache<DefaultNetworkReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultNetworkReservation? {
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

        func save(_ item: DefaultNetworkReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultNetworkReservation] {
            return inner.list()
        }
    }

    static func newCachedDefaultNetworkReservationStore(_ inner: MemoryDefaultNetworkReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultNetworkReservationStore {
        return CachedDefaultNetworkReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default network reservations. Empty fields match all.
    final class DefaultNetworkReservationQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultNetworkReservation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultNetworkReservation]) -> [DefaultNetworkReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultNetworkReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultNetworkReservations(_ store: any DefaultNetworkReservationStore, query: DefaultNetworkReservationQuery) -> [DefaultNetworkReservation] {
        return query.apply(store.list())
    }
}
