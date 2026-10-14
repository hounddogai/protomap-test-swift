import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense assignments by code.
    protocol DispenseAssignmentStore {
        func find(_ code: String) -> DispenseAssignment?
        func save(_ item: DispenseAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseAssignmentStore: DispenseAssignmentStore {
        var items: [String: DispenseAssignment]
        var order: [String]

        init(items: [String: DispenseAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseAssignment) {
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

        func list() -> [DispenseAssignment] {
            var out: [DispenseAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseAssignmentStore() -> any DispenseAssignmentStore {
        return MemoryDispenseAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseAssignmentStore: DispenseAssignmentStore {
        var inner: MemoryDispenseAssignmentStore
        var cache: TTLCache<DispenseAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseAssignmentStore, cache: TTLCache<DispenseAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseAssignment? {
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

        func save(_ item: DispenseAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseAssignment] {
            return inner.list()
        }
    }

    static func newCachedDispenseAssignmentStore(_ inner: MemoryDispenseAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseAssignmentStore {
        return CachedDispenseAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense assignments. Empty fields match all.
    final class DispenseAssignmentQuery {
        var facility: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseAssignment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [DispenseAssignment]) -> [DispenseAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseAssignments(_ store: any DispenseAssignmentStore, query: DispenseAssignmentQuery) -> [DispenseAssignment] {
        return query.apply(store.list())
    }
}
