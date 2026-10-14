import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution reservations by code.
    protocol SubstitutionReservationStore {
        func find(_ code: String) -> SubstitutionReservation?
        func save(_ item: SubstitutionReservation)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionReservationStore: SubstitutionReservationStore {
        var items: [String: SubstitutionReservation]
        var order: [String]

        init(items: [String: SubstitutionReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionReservation) {
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

        func list() -> [SubstitutionReservation] {
            var out: [SubstitutionReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionReservationStore() -> any SubstitutionReservationStore {
        return MemorySubstitutionReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionReservationStore: SubstitutionReservationStore {
        var inner: MemorySubstitutionReservationStore
        var cache: TTLCache<SubstitutionReservation>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionReservationStore, cache: TTLCache<SubstitutionReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionReservation? {
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

        func save(_ item: SubstitutionReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionReservation] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionReservationStore(_ inner: MemorySubstitutionReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionReservationStore {
        return CachedSubstitutionReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution reservations. Empty fields match all.
    final class SubstitutionReservationQuery {
        var title: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRetries: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionReservation]) -> [SubstitutionReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionReservations(_ store: any SubstitutionReservationStore, query: SubstitutionReservationQuery) -> [SubstitutionReservation] {
        return query.apply(store.list())
    }
}
