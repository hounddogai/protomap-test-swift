import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual cleaning assignments by code.
    protocol ManualCleaningAssignmentStore {
        func find(_ code: String) -> ManualCleaningAssignment?
        func save(_ item: ManualCleaningAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCleaningAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCleaningAssignmentStore: ManualCleaningAssignmentStore {
        var items: [String: ManualCleaningAssignment]
        var order: [String]

        init(items: [String: ManualCleaningAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCleaningAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCleaningAssignment) {
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

        func list() -> [ManualCleaningAssignment] {
            var out: [ManualCleaningAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCleaningAssignmentStore() -> any ManualCleaningAssignmentStore {
        return MemoryManualCleaningAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCleaningAssignmentStore: ManualCleaningAssignmentStore {
        var inner: MemoryManualCleaningAssignmentStore
        var cache: TTLCache<ManualCleaningAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCleaningAssignmentStore, cache: TTLCache<ManualCleaningAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCleaningAssignment? {
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

        func save(_ item: ManualCleaningAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCleaningAssignment] {
            return inner.list()
        }
    }

    static func newCachedManualCleaningAssignmentStore(_ inner: MemoryManualCleaningAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCleaningAssignmentStore {
        return CachedManualCleaningAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual cleaning assignments. Empty fields match all.
    final class ManualCleaningAssignmentQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCleaningAssignment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ManualCleaningAssignment]) -> [ManualCleaningAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCleaningAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCleaningAssignments(_ store: any ManualCleaningAssignmentStore, query: ManualCleaningAssignmentQuery) -> [ManualCleaningAssignment] {
        return query.apply(store.list())
    }
}
