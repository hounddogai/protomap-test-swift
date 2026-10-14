import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board reservations by code.
    protocol BedBoardReservationStore {
        func find(_ code: String) -> BedBoardReservation?
        func save(_ item: BedBoardReservation)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardReservationStore: BedBoardReservationStore {
        var items: [String: BedBoardReservation]
        var order: [String]

        init(items: [String: BedBoardReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardReservation) {
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

        func list() -> [BedBoardReservation] {
            var out: [BedBoardReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardReservationStore() -> any BedBoardReservationStore {
        return MemoryBedBoardReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardReservationStore: BedBoardReservationStore {
        var inner: MemoryBedBoardReservationStore
        var cache: TTLCache<BedBoardReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardReservationStore, cache: TTLCache<BedBoardReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardReservation? {
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

        func save(_ item: BedBoardReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardReservation] {
            return inner.list()
        }
    }

    static func newCachedBedBoardReservationStore(_ inner: MemoryBedBoardReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardReservationStore {
        return CachedBedBoardReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board reservations. Empty fields match all.
    final class BedBoardReservationQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardReservation]) -> [BedBoardReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardReservations(_ store: any BedBoardReservationStore, query: BedBoardReservationQuery) -> [BedBoardReservation] {
        return query.apply(store.list())
    }
}
