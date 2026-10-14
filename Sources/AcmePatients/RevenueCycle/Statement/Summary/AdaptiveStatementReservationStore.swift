import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive statement reservations by code.
    protocol AdaptiveStatementReservationStore {
        func find(_ code: String) -> AdaptiveStatementReservation?
        func save(_ item: AdaptiveStatementReservation)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveStatementReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveStatementReservationStore: AdaptiveStatementReservationStore {
        var items: [String: AdaptiveStatementReservation]
        var order: [String]

        init(items: [String: AdaptiveStatementReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveStatementReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveStatementReservation) {
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

        func list() -> [AdaptiveStatementReservation] {
            var out: [AdaptiveStatementReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveStatementReservationStore() -> any AdaptiveStatementReservationStore {
        return MemoryAdaptiveStatementReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveStatementReservationStore: AdaptiveStatementReservationStore {
        var inner: MemoryAdaptiveStatementReservationStore
        var cache: TTLCache<AdaptiveStatementReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveStatementReservationStore, cache: TTLCache<AdaptiveStatementReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveStatementReservation? {
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

        func save(_ item: AdaptiveStatementReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveStatementReservation] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveStatementReservationStore(_ inner: MemoryAdaptiveStatementReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveStatementReservationStore {
        return CachedAdaptiveStatementReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive statement reservations. Empty fields match all.
    final class AdaptiveStatementReservationQuery {
        var channel: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveStatementReservation) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveStatementReservation]) -> [AdaptiveStatementReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveStatementReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveStatementReservations(_ store: any AdaptiveStatementReservationStore, query: AdaptiveStatementReservationQuery) -> [AdaptiveStatementReservation] {
        return query.apply(store.list())
    }
}
