import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled disclosure reservations by code.
    protocol ScheduledDisclosureReservationStore {
        func find(_ code: String) -> ScheduledDisclosureReservation?
        func save(_ item: ScheduledDisclosureReservation)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledDisclosureReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledDisclosureReservationStore: ScheduledDisclosureReservationStore {
        var items: [String: ScheduledDisclosureReservation]
        var order: [String]

        init(items: [String: ScheduledDisclosureReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledDisclosureReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledDisclosureReservation) {
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

        func list() -> [ScheduledDisclosureReservation] {
            var out: [ScheduledDisclosureReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledDisclosureReservationStore() -> any ScheduledDisclosureReservationStore {
        return MemoryScheduledDisclosureReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledDisclosureReservationStore: ScheduledDisclosureReservationStore {
        var inner: MemoryScheduledDisclosureReservationStore
        var cache: TTLCache<ScheduledDisclosureReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledDisclosureReservationStore, cache: TTLCache<ScheduledDisclosureReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledDisclosureReservation? {
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

        func save(_ item: ScheduledDisclosureReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledDisclosureReservation] {
            return inner.list()
        }
    }

    static func newCachedScheduledDisclosureReservationStore(_ inner: MemoryScheduledDisclosureReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledDisclosureReservationStore {
        return CachedScheduledDisclosureReservationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled disclosure reservations. Empty fields match all.
    final class ScheduledDisclosureReservationQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledDisclosureReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledDisclosureReservation]) -> [ScheduledDisclosureReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledDisclosureReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledDisclosureReservations(_ store: any ScheduledDisclosureReservationStore, query: ScheduledDisclosureReservationQuery) -> [ScheduledDisclosureReservation] {
        return query.apply(store.list())
    }
}
