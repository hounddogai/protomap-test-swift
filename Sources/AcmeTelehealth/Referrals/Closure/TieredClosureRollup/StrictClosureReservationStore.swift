import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps strict closure reservations by code.
    protocol StrictClosureReservationStore {
        func find(_ code: String) -> StrictClosureReservation?
        func save(_ item: StrictClosureReservation)
        func remove(_ code: String) -> Bool
        func list() -> [StrictClosureReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictClosureReservationStore: StrictClosureReservationStore {
        var items: [String: StrictClosureReservation]
        var order: [String]

        init(items: [String: StrictClosureReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictClosureReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictClosureReservation) {
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

        func list() -> [StrictClosureReservation] {
            var out: [StrictClosureReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictClosureReservationStore() -> any StrictClosureReservationStore {
        return MemoryStrictClosureReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictClosureReservationStore: StrictClosureReservationStore {
        var inner: MemoryStrictClosureReservationStore
        var cache: TTLCache<StrictClosureReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictClosureReservationStore, cache: TTLCache<StrictClosureReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictClosureReservation? {
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

        func save(_ item: StrictClosureReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictClosureReservation] {
            return inner.list()
        }
    }

    static func newCachedStrictClosureReservationStore(_ inner: MemoryStrictClosureReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictClosureReservationStore {
        return CachedStrictClosureReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict closure reservations. Empty fields match all.
    final class StrictClosureReservationQuery {
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

        func matches(_ item: StrictClosureReservation) -> Bool {
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

        func apply(_ items: [StrictClosureReservation]) -> [StrictClosureReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictClosureReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictClosureReservations(_ store: any StrictClosureReservationStore, query: StrictClosureReservationQuery) -> [StrictClosureReservation] {
        return query.apply(store.list())
    }
}
