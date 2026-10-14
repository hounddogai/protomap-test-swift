import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge reservations by code.
    protocol ChargeReservationStore {
        func find(_ code: String) -> ChargeReservation?
        func save(_ item: ChargeReservation)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeReservationStore: ChargeReservationStore {
        var items: [String: ChargeReservation]
        var order: [String]

        init(items: [String: ChargeReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeReservation) {
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

        func list() -> [ChargeReservation] {
            var out: [ChargeReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeReservationStore() -> any ChargeReservationStore {
        return MemoryChargeReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeReservationStore: ChargeReservationStore {
        var inner: MemoryChargeReservationStore
        var cache: TTLCache<ChargeReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeReservationStore, cache: TTLCache<ChargeReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeReservation? {
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

        func save(_ item: ChargeReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeReservation] {
            return inner.list()
        }
    }

    static func newCachedChargeReservationStore(_ inner: MemoryChargeReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeReservationStore {
        return CachedChargeReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge reservations. Empty fields match all.
    final class ChargeReservationQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeReservation]) -> [ChargeReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeReservations(_ store: any ChargeReservationStore, query: ChargeReservationQuery) -> [ChargeReservation] {
        return query.apply(store.list())
    }
}
