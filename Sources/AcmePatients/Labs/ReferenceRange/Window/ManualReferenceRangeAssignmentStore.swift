import AcmePlatform
import Foundation

extension Labs {
    /// Keeps manual reference range assignments by code.
    protocol ManualReferenceRangeAssignmentStore {
        func find(_ code: String) -> ManualReferenceRangeAssignment?
        func save(_ item: ManualReferenceRangeAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [ManualReferenceRangeAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualReferenceRangeAssignmentStore: ManualReferenceRangeAssignmentStore {
        var items: [String: ManualReferenceRangeAssignment]
        var order: [String]

        init(items: [String: ManualReferenceRangeAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualReferenceRangeAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualReferenceRangeAssignment) {
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

        func list() -> [ManualReferenceRangeAssignment] {
            var out: [ManualReferenceRangeAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualReferenceRangeAssignmentStore() -> any ManualReferenceRangeAssignmentStore {
        return MemoryManualReferenceRangeAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualReferenceRangeAssignmentStore: ManualReferenceRangeAssignmentStore {
        var inner: MemoryManualReferenceRangeAssignmentStore
        var cache: TTLCache<ManualReferenceRangeAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualReferenceRangeAssignmentStore, cache: TTLCache<ManualReferenceRangeAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualReferenceRangeAssignment? {
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

        func save(_ item: ManualReferenceRangeAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualReferenceRangeAssignment] {
            return inner.list()
        }
    }

    static func newCachedManualReferenceRangeAssignmentStore(_ inner: MemoryManualReferenceRangeAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualReferenceRangeAssignmentStore {
        return CachedManualReferenceRangeAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual reference range assignments. Empty fields match all.
    final class ManualReferenceRangeAssignmentQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualReferenceRangeAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ManualReferenceRangeAssignment]) -> [ManualReferenceRangeAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualReferenceRangeAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualReferenceRangeAssignments(_ store: any ManualReferenceRangeAssignmentStore, query: ManualReferenceRangeAssignmentQuery) -> [ManualReferenceRangeAssignment] {
        return query.apply(store.list())
    }
}
