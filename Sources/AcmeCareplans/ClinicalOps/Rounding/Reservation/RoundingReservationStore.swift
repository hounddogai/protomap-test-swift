import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding reservations by code.
    protocol RoundingReservationStore {
        func find(_ code: String) -> RoundingReservation?
        func save(_ item: RoundingReservation)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingReservationStore: RoundingReservationStore {
        var items: [String: RoundingReservation]
        var order: [String]

        init(items: [String: RoundingReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingReservation) {
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

        func list() -> [RoundingReservation] {
            var out: [RoundingReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingReservationStore() -> any RoundingReservationStore {
        return MemoryRoundingReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingReservationStore: RoundingReservationStore {
        var inner: MemoryRoundingReservationStore
        var cache: TTLCache<RoundingReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingReservationStore, cache: TTLCache<RoundingReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingReservation? {
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

        func save(_ item: RoundingReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingReservation] {
            return inner.list()
        }
    }

    static func newCachedRoundingReservationStore(_ inner: MemoryRoundingReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingReservationStore {
        return CachedRoundingReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding reservations. Empty fields match all.
    final class RoundingReservationQuery {
        var category: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minPriority: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingReservation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingReservation]) -> [RoundingReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingReservations(_ store: any RoundingReservationStore, query: RoundingReservationQuery) -> [RoundingReservation] {
        return query.apply(store.list())
    }
}
