import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual formulary assignments by code.
    protocol ManualFormularyAssignmentStore {
        func find(_ code: String) -> ManualFormularyAssignment?
        func save(_ item: ManualFormularyAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [ManualFormularyAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualFormularyAssignmentStore: ManualFormularyAssignmentStore {
        var items: [String: ManualFormularyAssignment]
        var order: [String]

        init(items: [String: ManualFormularyAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualFormularyAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualFormularyAssignment) {
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

        func list() -> [ManualFormularyAssignment] {
            var out: [ManualFormularyAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualFormularyAssignmentStore() -> any ManualFormularyAssignmentStore {
        return MemoryManualFormularyAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualFormularyAssignmentStore: ManualFormularyAssignmentStore {
        var inner: MemoryManualFormularyAssignmentStore
        var cache: TTLCache<ManualFormularyAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualFormularyAssignmentStore, cache: TTLCache<ManualFormularyAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualFormularyAssignment? {
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

        func save(_ item: ManualFormularyAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualFormularyAssignment] {
            return inner.list()
        }
    }

    static func newCachedManualFormularyAssignmentStore(_ inner: MemoryManualFormularyAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualFormularyAssignmentStore {
        return CachedManualFormularyAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual formulary assignments. Empty fields match all.
    final class ManualFormularyAssignmentQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualFormularyAssignment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualFormularyAssignment]) -> [ManualFormularyAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualFormularyAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualFormularyAssignments(_ store: any ManualFormularyAssignmentStore, query: ManualFormularyAssignmentQuery) -> [ManualFormularyAssignment] {
        return query.apply(store.list())
    }
}
