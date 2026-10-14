import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default shift reservations by code.
    protocol DefaultShiftReservationStore {
        func find(_ code: String) -> DefaultShiftReservation?
        func save(_ item: DefaultShiftReservation)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultShiftReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultShiftReservationStore: DefaultShiftReservationStore {
        var items: [String: DefaultShiftReservation]
        var order: [String]

        init(items: [String: DefaultShiftReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultShiftReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultShiftReservation) {
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

        func list() -> [DefaultShiftReservation] {
            var out: [DefaultShiftReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultShiftReservationStore() -> any DefaultShiftReservationStore {
        return MemoryDefaultShiftReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultShiftReservationStore: DefaultShiftReservationStore {
        var inner: MemoryDefaultShiftReservationStore
        var cache: TTLCache<DefaultShiftReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultShiftReservationStore, cache: TTLCache<DefaultShiftReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultShiftReservation? {
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

        func save(_ item: DefaultShiftReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultShiftReservation] {
            return inner.list()
        }
    }

    static func newCachedDefaultShiftReservationStore(_ inner: MemoryDefaultShiftReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultShiftReservationStore {
        return CachedDefaultShiftReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default shift reservations. Empty fields match all.
    final class DefaultShiftReservationQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultShiftReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultShiftReservation]) -> [DefaultShiftReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultShiftReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultShiftReservations(_ store: any DefaultShiftReservationStore, query: DefaultShiftReservationQuery) -> [DefaultShiftReservation] {
        return query.apply(store.list())
    }
}
