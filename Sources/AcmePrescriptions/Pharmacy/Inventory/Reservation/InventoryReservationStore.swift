import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory reservations by code.
    protocol InventoryReservationStore {
        func find(_ code: String) -> InventoryReservation?
        func save(_ item: InventoryReservation)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryReservationStore: InventoryReservationStore {
        var items: [String: InventoryReservation]
        var order: [String]

        init(items: [String: InventoryReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryReservation) {
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

        func list() -> [InventoryReservation] {
            var out: [InventoryReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryReservationStore() -> any InventoryReservationStore {
        return MemoryInventoryReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryReservationStore: InventoryReservationStore {
        var inner: MemoryInventoryReservationStore
        var cache: TTLCache<InventoryReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryReservationStore, cache: TTLCache<InventoryReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryReservation? {
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

        func save(_ item: InventoryReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryReservation] {
            return inner.list()
        }
    }

    static func newCachedInventoryReservationStore(_ inner: MemoryInventoryReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryReservationStore {
        return CachedInventoryReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory reservations. Empty fields match all.
    final class InventoryReservationQuery {
        var unit: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRevision: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryReservation) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryReservation]) -> [InventoryReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryReservations(_ store: any InventoryReservationStore, query: InventoryReservationQuery) -> [InventoryReservation] {
        return query.apply(store.list())
    }
}
