import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped recall reservations by code.
    protocol CappedRecallReservationStore {
        func find(_ code: String) -> CappedRecallReservation?
        func save(_ item: CappedRecallReservation)
        func remove(_ code: String) -> Bool
        func list() -> [CappedRecallReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedRecallReservationStore: CappedRecallReservationStore {
        var items: [String: CappedRecallReservation]
        var order: [String]

        init(items: [String: CappedRecallReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedRecallReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedRecallReservation) {
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

        func list() -> [CappedRecallReservation] {
            var out: [CappedRecallReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedRecallReservationStore() -> any CappedRecallReservationStore {
        return MemoryCappedRecallReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedRecallReservationStore: CappedRecallReservationStore {
        var inner: MemoryCappedRecallReservationStore
        var cache: TTLCache<CappedRecallReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedRecallReservationStore, cache: TTLCache<CappedRecallReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedRecallReservation? {
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

        func save(_ item: CappedRecallReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedRecallReservation] {
            return inner.list()
        }
    }

    static func newCachedCappedRecallReservationStore(_ inner: MemoryCappedRecallReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedRecallReservationStore {
        return CachedCappedRecallReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped recall reservations. Empty fields match all.
    final class CappedRecallReservationQuery {
        var country: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRatio: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedRecallReservation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [CappedRecallReservation]) -> [CappedRecallReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedRecallReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedRecallReservations(_ store: any CappedRecallReservationStore, query: CappedRecallReservationQuery) -> [CappedRecallReservation] {
        return query.apply(store.list())
    }
}
