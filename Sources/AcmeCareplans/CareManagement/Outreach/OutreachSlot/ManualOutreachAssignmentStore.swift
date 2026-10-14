import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual outreach assignments by code.
    protocol ManualOutreachAssignmentStore {
        func find(_ code: String) -> ManualOutreachAssignment?
        func save(_ item: ManualOutreachAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [ManualOutreachAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualOutreachAssignmentStore: ManualOutreachAssignmentStore {
        var items: [String: ManualOutreachAssignment]
        var order: [String]

        init(items: [String: ManualOutreachAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualOutreachAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualOutreachAssignment) {
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

        func list() -> [ManualOutreachAssignment] {
            var out: [ManualOutreachAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualOutreachAssignmentStore() -> any ManualOutreachAssignmentStore {
        return MemoryManualOutreachAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualOutreachAssignmentStore: ManualOutreachAssignmentStore {
        var inner: MemoryManualOutreachAssignmentStore
        var cache: TTLCache<ManualOutreachAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualOutreachAssignmentStore, cache: TTLCache<ManualOutreachAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualOutreachAssignment? {
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

        func save(_ item: ManualOutreachAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualOutreachAssignment] {
            return inner.list()
        }
    }

    static func newCachedManualOutreachAssignmentStore(_ inner: MemoryManualOutreachAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualOutreachAssignmentStore {
        return CachedManualOutreachAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual outreach assignments. Empty fields match all.
    final class ManualOutreachAssignmentQuery {
        var label: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualOutreachAssignment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualOutreachAssignment]) -> [ManualOutreachAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualOutreachAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualOutreachAssignments(_ store: any ManualOutreachAssignmentStore, query: ManualOutreachAssignmentQuery) -> [ManualOutreachAssignment] {
        return query.apply(store.list())
    }
}
