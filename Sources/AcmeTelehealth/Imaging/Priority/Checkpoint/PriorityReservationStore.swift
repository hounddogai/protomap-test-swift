import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority reservations by code.
    protocol PriorityReservationStore {
        func find(_ code: String) -> PriorityReservation?
        func save(_ item: PriorityReservation)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityReservationStore: PriorityReservationStore {
        var items: [String: PriorityReservation]
        var order: [String]

        init(items: [String: PriorityReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityReservation) {
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

        func list() -> [PriorityReservation] {
            var out: [PriorityReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityReservationStore() -> any PriorityReservationStore {
        return MemoryPriorityReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityReservationStore: PriorityReservationStore {
        var inner: MemoryPriorityReservationStore
        var cache: TTLCache<PriorityReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityReservationStore, cache: TTLCache<PriorityReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityReservation? {
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

        func save(_ item: PriorityReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityReservation] {
            return inner.list()
        }
    }

    static func newCachedPriorityReservationStore(_ inner: MemoryPriorityReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityReservationStore {
        return CachedPriorityReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority reservations. Empty fields match all.
    final class PriorityReservationQuery {
        var name: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityReservation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PriorityReservation]) -> [PriorityReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityReservations(_ store: any PriorityReservationStore, query: PriorityReservationQuery) -> [PriorityReservation] {
        return query.apply(store.list())
    }
}
