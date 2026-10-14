import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim reservations by code.
    protocol ClaimReservationStore {
        func find(_ code: String) -> ClaimReservation?
        func save(_ item: ClaimReservation)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimReservationStore: ClaimReservationStore {
        var items: [String: ClaimReservation]
        var order: [String]

        init(items: [String: ClaimReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimReservation) {
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

        func list() -> [ClaimReservation] {
            var out: [ClaimReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimReservationStore() -> any ClaimReservationStore {
        return MemoryClaimReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimReservationStore: ClaimReservationStore {
        var inner: MemoryClaimReservationStore
        var cache: TTLCache<ClaimReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimReservationStore, cache: TTLCache<ClaimReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimReservation? {
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

        func save(_ item: ClaimReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimReservation] {
            return inner.list()
        }
    }

    static func newCachedClaimReservationStore(_ inner: MemoryClaimReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimReservationStore {
        return CachedClaimReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim reservations. Empty fields match all.
    final class ClaimReservationQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimReservation]) -> [ClaimReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimReservations(_ store: any ClaimReservationStore, query: ClaimReservationQuery) -> [ClaimReservation] {
        return query.apply(store.list())
    }
}
