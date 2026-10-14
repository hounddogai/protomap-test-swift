import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach reservations by code.
    protocol OutreachReservationStore {
        func find(_ code: String) -> OutreachReservation?
        func save(_ item: OutreachReservation)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachReservationStore: OutreachReservationStore {
        var items: [String: OutreachReservation]
        var order: [String]

        init(items: [String: OutreachReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachReservation) {
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

        func list() -> [OutreachReservation] {
            var out: [OutreachReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachReservationStore() -> any OutreachReservationStore {
        return MemoryOutreachReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachReservationStore: OutreachReservationStore {
        var inner: MemoryOutreachReservationStore
        var cache: TTLCache<OutreachReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachReservationStore, cache: TTLCache<OutreachReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachReservation? {
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

        func save(_ item: OutreachReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachReservation] {
            return inner.list()
        }
    }

    static func newCachedOutreachReservationStore(_ inner: MemoryOutreachReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachReservationStore {
        return CachedOutreachReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach reservations. Empty fields match all.
    final class OutreachReservationQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachReservation]) -> [OutreachReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachReservations(_ store: any OutreachReservationStore, query: OutreachReservationQuery) -> [OutreachReservation] {
        return query.apply(store.list())
    }
}
