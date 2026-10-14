import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel reservations by code.
    protocol PanelReservationStore {
        func find(_ code: String) -> PanelReservation?
        func save(_ item: PanelReservation)
        func remove(_ code: String) -> Bool
        func list() -> [PanelReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelReservationStore: PanelReservationStore {
        var items: [String: PanelReservation]
        var order: [String]

        init(items: [String: PanelReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelReservation) {
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

        func list() -> [PanelReservation] {
            var out: [PanelReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelReservationStore() -> any PanelReservationStore {
        return MemoryPanelReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelReservationStore: PanelReservationStore {
        var inner: MemoryPanelReservationStore
        var cache: TTLCache<PanelReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelReservationStore, cache: TTLCache<PanelReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelReservation? {
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

        func save(_ item: PanelReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelReservation] {
            return inner.list()
        }
    }

    static func newCachedPanelReservationStore(_ inner: MemoryPanelReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelReservationStore {
        return CachedPanelReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel reservations. Empty fields match all.
    final class PanelReservationQuery {
        var unit: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelReservation) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelReservation]) -> [PanelReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelReservations(_ store: any PanelReservationStore, query: PanelReservationQuery) -> [PanelReservation] {
        return query.apply(store.list())
    }
}
