import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy reservations by code.
    protocol ProxyReservationStore {
        func find(_ code: String) -> ProxyReservation?
        func save(_ item: ProxyReservation)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyReservationStore: ProxyReservationStore {
        var items: [String: ProxyReservation]
        var order: [String]

        init(items: [String: ProxyReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyReservation) {
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

        func list() -> [ProxyReservation] {
            var out: [ProxyReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyReservationStore() -> any ProxyReservationStore {
        return MemoryProxyReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyReservationStore: ProxyReservationStore {
        var inner: MemoryProxyReservationStore
        var cache: TTLCache<ProxyReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyReservationStore, cache: TTLCache<ProxyReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyReservation? {
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

        func save(_ item: ProxyReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyReservation] {
            return inner.list()
        }
    }

    static func newCachedProxyReservationStore(_ inner: MemoryProxyReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyReservationStore {
        return CachedProxyReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy reservations. Empty fields match all.
    final class ProxyReservationQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyReservation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyReservation]) -> [ProxyReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyReservations(_ store: any ProxyReservationStore, query: ProxyReservationQuery) -> [ProxyReservation] {
        return query.apply(store.list())
    }
}
