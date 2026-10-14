import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback referral reservations by code.
    protocol FallbackReferralReservationStore {
        func find(_ code: String) -> FallbackReferralReservation?
        func save(_ item: FallbackReferralReservation)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackReferralReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackReferralReservationStore: FallbackReferralReservationStore {
        var items: [String: FallbackReferralReservation]
        var order: [String]

        init(items: [String: FallbackReferralReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackReferralReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackReferralReservation) {
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

        func list() -> [FallbackReferralReservation] {
            var out: [FallbackReferralReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackReferralReservationStore() -> any FallbackReferralReservationStore {
        return MemoryFallbackReferralReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackReferralReservationStore: FallbackReferralReservationStore {
        var inner: MemoryFallbackReferralReservationStore
        var cache: TTLCache<FallbackReferralReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackReferralReservationStore, cache: TTLCache<FallbackReferralReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackReferralReservation? {
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

        func save(_ item: FallbackReferralReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackReferralReservation] {
            return inner.list()
        }
    }

    static func newCachedFallbackReferralReservationStore(_ inner: MemoryFallbackReferralReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackReferralReservationStore {
        return CachedFallbackReferralReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback referral reservations. Empty fields match all.
    final class FallbackReferralReservationQuery {
        var facility: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackReferralReservation) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackReferralReservation]) -> [FallbackReferralReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackReferralReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackReferralReservations(_ store: any FallbackReferralReservationStore, query: FallbackReferralReservationQuery) -> [FallbackReferralReservation] {
        return query.apply(store.list())
    }
}
