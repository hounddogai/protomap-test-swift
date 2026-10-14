import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps weighted credential reservations by code.
    protocol WeightedCredentialReservationStore {
        func find(_ code: String) -> WeightedCredentialReservation?
        func save(_ item: WeightedCredentialReservation)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedCredentialReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedCredentialReservationStore: WeightedCredentialReservationStore {
        var items: [String: WeightedCredentialReservation]
        var order: [String]

        init(items: [String: WeightedCredentialReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedCredentialReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedCredentialReservation) {
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

        func list() -> [WeightedCredentialReservation] {
            var out: [WeightedCredentialReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedCredentialReservationStore() -> any WeightedCredentialReservationStore {
        return MemoryWeightedCredentialReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedCredentialReservationStore: WeightedCredentialReservationStore {
        var inner: MemoryWeightedCredentialReservationStore
        var cache: TTLCache<WeightedCredentialReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedCredentialReservationStore, cache: TTLCache<WeightedCredentialReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedCredentialReservation? {
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

        func save(_ item: WeightedCredentialReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedCredentialReservation] {
            return inner.list()
        }
    }

    static func newCachedWeightedCredentialReservationStore(_ inner: MemoryWeightedCredentialReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedCredentialReservationStore {
        return CachedWeightedCredentialReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted credential reservations. Empty fields match all.
    final class WeightedCredentialReservationQuery {
        var country: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedCredentialReservation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedCredentialReservation]) -> [WeightedCredentialReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedCredentialReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedCredentialReservations(_ store: any WeightedCredentialReservationStore, query: WeightedCredentialReservationQuery) -> [WeightedCredentialReservation] {
        return query.apply(store.list())
    }
}
