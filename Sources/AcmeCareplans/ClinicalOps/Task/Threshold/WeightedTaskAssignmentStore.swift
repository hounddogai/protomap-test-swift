import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps weighted task assignments by code.
    protocol WeightedTaskAssignmentStore {
        func find(_ code: String) -> WeightedTaskAssignment?
        func save(_ item: WeightedTaskAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedTaskAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedTaskAssignmentStore: WeightedTaskAssignmentStore {
        var items: [String: WeightedTaskAssignment]
        var order: [String]

        init(items: [String: WeightedTaskAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedTaskAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedTaskAssignment) {
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

        func list() -> [WeightedTaskAssignment] {
            var out: [WeightedTaskAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedTaskAssignmentStore() -> any WeightedTaskAssignmentStore {
        return MemoryWeightedTaskAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedTaskAssignmentStore: WeightedTaskAssignmentStore {
        var inner: MemoryWeightedTaskAssignmentStore
        var cache: TTLCache<WeightedTaskAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedTaskAssignmentStore, cache: TTLCache<WeightedTaskAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedTaskAssignment? {
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

        func save(_ item: WeightedTaskAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedTaskAssignment] {
            return inner.list()
        }
    }

    static func newCachedWeightedTaskAssignmentStore(_ inner: MemoryWeightedTaskAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedTaskAssignmentStore {
        return CachedWeightedTaskAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted task assignments. Empty fields match all.
    final class WeightedTaskAssignmentQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedTaskAssignment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedTaskAssignment]) -> [WeightedTaskAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedTaskAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedTaskAssignments(_ store: any WeightedTaskAssignmentStore, query: WeightedTaskAssignmentQuery) -> [WeightedTaskAssignment] {
        return query.apply(store.list())
    }
}
