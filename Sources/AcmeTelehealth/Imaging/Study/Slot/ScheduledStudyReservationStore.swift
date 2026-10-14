import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps scheduled study reservations by code.
    protocol ScheduledStudyReservationStore {
        func find(_ code: String) -> ScheduledStudyReservation?
        func save(_ item: ScheduledStudyReservation)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledStudyReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledStudyReservationStore: ScheduledStudyReservationStore {
        var items: [String: ScheduledStudyReservation]
        var order: [String]

        init(items: [String: ScheduledStudyReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledStudyReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledStudyReservation) {
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

        func list() -> [ScheduledStudyReservation] {
            var out: [ScheduledStudyReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledStudyReservationStore() -> any ScheduledStudyReservationStore {
        return MemoryScheduledStudyReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledStudyReservationStore: ScheduledStudyReservationStore {
        var inner: MemoryScheduledStudyReservationStore
        var cache: TTLCache<ScheduledStudyReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledStudyReservationStore, cache: TTLCache<ScheduledStudyReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledStudyReservation? {
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

        func save(_ item: ScheduledStudyReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledStudyReservation] {
            return inner.list()
        }
    }

    static func newCachedScheduledStudyReservationStore(_ inner: MemoryScheduledStudyReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledStudyReservationStore {
        return CachedScheduledStudyReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled study reservations. Empty fields match all.
    final class ScheduledStudyReservationQuery {
        var source: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledStudyReservation) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledStudyReservation]) -> [ScheduledStudyReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledStudyReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledStudyReservations(_ store: any ScheduledStudyReservationStore, query: ScheduledStudyReservationQuery) -> [ScheduledStudyReservation] {
        return query.apply(store.list())
    }
}
