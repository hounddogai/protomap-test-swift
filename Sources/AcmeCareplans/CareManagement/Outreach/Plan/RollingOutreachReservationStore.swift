import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling outreach reservations by code.
    protocol RollingOutreachReservationStore {
        func find(_ code: String) -> RollingOutreachReservation?
        func save(_ item: RollingOutreachReservation)
        func remove(_ code: String) -> Bool
        func list() -> [RollingOutreachReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingOutreachReservationStore: RollingOutreachReservationStore {
        var items: [String: RollingOutreachReservation]
        var order: [String]

        init(items: [String: RollingOutreachReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingOutreachReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingOutreachReservation) {
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

        func list() -> [RollingOutreachReservation] {
            var out: [RollingOutreachReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingOutreachReservationStore() -> any RollingOutreachReservationStore {
        return MemoryRollingOutreachReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingOutreachReservationStore: RollingOutreachReservationStore {
        var inner: MemoryRollingOutreachReservationStore
        var cache: TTLCache<RollingOutreachReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingOutreachReservationStore, cache: TTLCache<RollingOutreachReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingOutreachReservation? {
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

        func save(_ item: RollingOutreachReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingOutreachReservation] {
            return inner.list()
        }
    }

    static func newCachedRollingOutreachReservationStore(_ inner: MemoryRollingOutreachReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingOutreachReservationStore {
        return CachedRollingOutreachReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling outreach reservations. Empty fields match all.
    final class RollingOutreachReservationQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingOutreachReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingOutreachReservation]) -> [RollingOutreachReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingOutreachReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingOutreachReservations(_ store: any RollingOutreachReservationStore, query: RollingOutreachReservationQuery) -> [RollingOutreachReservation] {
        return query.apply(store.list())
    }
}
