import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer reservations by code.
    protocol TransferReservationStore {
        func find(_ code: String) -> TransferReservation?
        func save(_ item: TransferReservation)
        func remove(_ code: String) -> Bool
        func list() -> [TransferReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferReservationStore: TransferReservationStore {
        var items: [String: TransferReservation]
        var order: [String]

        init(items: [String: TransferReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferReservation) {
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

        func list() -> [TransferReservation] {
            var out: [TransferReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferReservationStore() -> any TransferReservationStore {
        return MemoryTransferReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferReservationStore: TransferReservationStore {
        var inner: MemoryTransferReservationStore
        var cache: TTLCache<TransferReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferReservationStore, cache: TTLCache<TransferReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferReservation? {
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

        func save(_ item: TransferReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferReservation] {
            return inner.list()
        }
    }

    static func newCachedTransferReservationStore(_ inner: MemoryTransferReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferReservationStore {
        return CachedTransferReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer reservations. Empty fields match all.
    final class TransferReservationQuery {
        var country: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCost: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferReservation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferReservation]) -> [TransferReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferReservations(_ store: any TransferReservationStore, query: TransferReservationQuery) -> [TransferReservation] {
        return query.apply(store.list())
    }
}
