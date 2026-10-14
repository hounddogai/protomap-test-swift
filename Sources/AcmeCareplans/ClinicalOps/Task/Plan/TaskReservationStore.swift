import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task reservations by code.
    protocol TaskReservationStore {
        func find(_ code: String) -> TaskReservation?
        func save(_ item: TaskReservation)
        func remove(_ code: String) -> Bool
        func list() -> [TaskReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskReservationStore: TaskReservationStore {
        var items: [String: TaskReservation]
        var order: [String]

        init(items: [String: TaskReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskReservation) {
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

        func list() -> [TaskReservation] {
            var out: [TaskReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskReservationStore() -> any TaskReservationStore {
        return MemoryTaskReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskReservationStore: TaskReservationStore {
        var inner: MemoryTaskReservationStore
        var cache: TTLCache<TaskReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskReservationStore, cache: TTLCache<TaskReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskReservation? {
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

        func save(_ item: TaskReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskReservation] {
            return inner.list()
        }
    }

    static func newCachedTaskReservationStore(_ inner: MemoryTaskReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskReservationStore {
        return CachedTaskReservationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task reservations. Empty fields match all.
    final class TaskReservationQuery {
        var region: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskReservation) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskReservation]) -> [TaskReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskReservations(_ store: any TaskReservationStore, query: TaskReservationQuery) -> [TaskReservation] {
        return query.apply(store.list())
    }
}
