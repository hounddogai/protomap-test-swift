import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps scheduled dispense reservations by code.
    protocol ScheduledDispenseReservationStore {
        func find(_ code: String) -> ScheduledDispenseReservation?
        func save(_ item: ScheduledDispenseReservation)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledDispenseReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledDispenseReservationStore: ScheduledDispenseReservationStore {
        var items: [String: ScheduledDispenseReservation]
        var order: [String]

        init(items: [String: ScheduledDispenseReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledDispenseReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledDispenseReservation) {
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

        func list() -> [ScheduledDispenseReservation] {
            var out: [ScheduledDispenseReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledDispenseReservationStore() -> any ScheduledDispenseReservationStore {
        return MemoryScheduledDispenseReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledDispenseReservationStore: ScheduledDispenseReservationStore {
        var inner: MemoryScheduledDispenseReservationStore
        var cache: TTLCache<ScheduledDispenseReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledDispenseReservationStore, cache: TTLCache<ScheduledDispenseReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledDispenseReservation? {
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

        func save(_ item: ScheduledDispenseReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledDispenseReservation] {
            return inner.list()
        }
    }

    static func newCachedScheduledDispenseReservationStore(_ inner: MemoryScheduledDispenseReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledDispenseReservationStore {
        return CachedScheduledDispenseReservationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled dispense reservations. Empty fields match all.
    final class ScheduledDispenseReservationQuery {
        var category: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRetries: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledDispenseReservation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [ScheduledDispenseReservation]) -> [ScheduledDispenseReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledDispenseReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledDispenseReservations(_ store: any ScheduledDispenseReservationStore, query: ScheduledDispenseReservationQuery) -> [ScheduledDispenseReservation] {
        return query.apply(store.list())
    }
}
