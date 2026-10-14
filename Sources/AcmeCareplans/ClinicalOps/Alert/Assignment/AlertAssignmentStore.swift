import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert assignments by code.
    protocol AlertAssignmentStore {
        func find(_ code: String) -> AlertAssignment?
        func save(_ item: AlertAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [AlertAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertAssignmentStore: AlertAssignmentStore {
        var items: [String: AlertAssignment]
        var order: [String]

        init(items: [String: AlertAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertAssignment) {
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

        func list() -> [AlertAssignment] {
            var out: [AlertAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertAssignmentStore() -> any AlertAssignmentStore {
        return MemoryAlertAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertAssignmentStore: AlertAssignmentStore {
        var inner: MemoryAlertAssignmentStore
        var cache: TTLCache<AlertAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertAssignmentStore, cache: TTLCache<AlertAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertAssignment? {
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

        func save(_ item: AlertAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertAssignment] {
            return inner.list()
        }
    }

    static func newCachedAlertAssignmentStore(_ inner: MemoryAlertAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertAssignmentStore {
        return CachedAlertAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert assignments. Empty fields match all.
    final class AlertAssignmentQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertAssignment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertAssignment]) -> [AlertAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertAssignments(_ store: any AlertAssignmentStore, query: AlertAssignmentQuery) -> [AlertAssignment] {
        return query.apply(store.list())
    }
}
