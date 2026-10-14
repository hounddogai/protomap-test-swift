import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read reservations by code.
    protocol ReadReservationStore {
        func find(_ code: String) -> ReadReservation?
        func save(_ item: ReadReservation)
        func remove(_ code: String) -> Bool
        func list() -> [ReadReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadReservationStore: ReadReservationStore {
        var items: [String: ReadReservation]
        var order: [String]

        init(items: [String: ReadReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadReservation) {
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

        func list() -> [ReadReservation] {
            var out: [ReadReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadReservationStore() -> any ReadReservationStore {
        return MemoryReadReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadReservationStore: ReadReservationStore {
        var inner: MemoryReadReservationStore
        var cache: TTLCache<ReadReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadReservationStore, cache: TTLCache<ReadReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadReservation? {
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

        func save(_ item: ReadReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadReservation] {
            return inner.list()
        }
    }

    static func newCachedReadReservationStore(_ inner: MemoryReadReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadReservationStore {
        return CachedReadReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read reservations. Empty fields match all.
    final class ReadReservationQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadReservation]) -> [ReadReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadReservations(_ store: any ReadReservationStore, query: ReadReservationQuery) -> [ReadReservation] {
        return query.apply(store.list())
    }
}
