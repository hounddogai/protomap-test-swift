import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness reservations by code.
    protocol WitnessReservationStore {
        func find(_ code: String) -> WitnessReservation?
        func save(_ item: WitnessReservation)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessReservationStore: WitnessReservationStore {
        var items: [String: WitnessReservation]
        var order: [String]

        init(items: [String: WitnessReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessReservation) {
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

        func list() -> [WitnessReservation] {
            var out: [WitnessReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessReservationStore() -> any WitnessReservationStore {
        return MemoryWitnessReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessReservationStore: WitnessReservationStore {
        var inner: MemoryWitnessReservationStore
        var cache: TTLCache<WitnessReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessReservationStore, cache: TTLCache<WitnessReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessReservation? {
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

        func save(_ item: WitnessReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessReservation] {
            return inner.list()
        }
    }

    static func newCachedWitnessReservationStore(_ inner: MemoryWitnessReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessReservationStore {
        return CachedWitnessReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness reservations. Empty fields match all.
    final class WitnessReservationQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessReservation]) -> [WitnessReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessReservations(_ store: any WitnessReservationStore, query: WitnessReservationQuery) -> [WitnessReservation] {
        return query.apply(store.list())
    }
}
