import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps default remittance reservations by code.
    protocol DefaultRemittanceReservationStore {
        func find(_ code: String) -> DefaultRemittanceReservation?
        func save(_ item: DefaultRemittanceReservation)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRemittanceReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRemittanceReservationStore: DefaultRemittanceReservationStore {
        var items: [String: DefaultRemittanceReservation]
        var order: [String]

        init(items: [String: DefaultRemittanceReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRemittanceReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRemittanceReservation) {
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

        func list() -> [DefaultRemittanceReservation] {
            var out: [DefaultRemittanceReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRemittanceReservationStore() -> any DefaultRemittanceReservationStore {
        return MemoryDefaultRemittanceReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRemittanceReservationStore: DefaultRemittanceReservationStore {
        var inner: MemoryDefaultRemittanceReservationStore
        var cache: TTLCache<DefaultRemittanceReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRemittanceReservationStore, cache: TTLCache<DefaultRemittanceReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRemittanceReservation? {
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

        func save(_ item: DefaultRemittanceReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRemittanceReservation] {
            return inner.list()
        }
    }

    static func newCachedDefaultRemittanceReservationStore(_ inner: MemoryDefaultRemittanceReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRemittanceReservationStore {
        return CachedDefaultRemittanceReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default remittance reservations. Empty fields match all.
    final class DefaultRemittanceReservationQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRemittanceReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultRemittanceReservation]) -> [DefaultRemittanceReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRemittanceReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRemittanceReservations(_ store: any DefaultRemittanceReservationStore, query: DefaultRemittanceReservationQuery) -> [DefaultRemittanceReservation] {
        return query.apply(store.list())
    }
}
