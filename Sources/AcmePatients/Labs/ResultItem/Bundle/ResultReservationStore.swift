import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result reservations by code.
    protocol ResultReservationStore {
        func find(_ code: String) -> ResultReservation?
        func save(_ item: ResultReservation)
        func remove(_ code: String) -> Bool
        func list() -> [ResultReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultReservationStore: ResultReservationStore {
        var items: [String: ResultReservation]
        var order: [String]

        init(items: [String: ResultReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultReservation) {
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

        func list() -> [ResultReservation] {
            var out: [ResultReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultReservationStore() -> any ResultReservationStore {
        return MemoryResultReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultReservationStore: ResultReservationStore {
        var inner: MemoryResultReservationStore
        var cache: TTLCache<ResultReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultReservationStore, cache: TTLCache<ResultReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultReservation? {
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

        func save(_ item: ResultReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultReservation] {
            return inner.list()
        }
    }

    static func newCachedResultReservationStore(_ inner: MemoryResultReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultReservationStore {
        return CachedResultReservationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result reservations. Empty fields match all.
    final class ResultReservationQuery {
        var category: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minAmount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultReservation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [ResultReservation]) -> [ResultReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultReservations(_ store: any ResultReservationStore, query: ResultReservationQuery) -> [ResultReservation] {
        return query.apply(store.list())
    }
}
