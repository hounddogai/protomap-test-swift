import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps rolling acuity plan assignments by code.
    protocol RollingAcuityPlanAssignmentStore {
        func find(_ code: String) -> RollingAcuityPlanAssignment?
        func save(_ item: RollingAcuityPlanAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAcuityPlanAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAcuityPlanAssignmentStore: RollingAcuityPlanAssignmentStore {
        var items: [String: RollingAcuityPlanAssignment]
        var order: [String]

        init(items: [String: RollingAcuityPlanAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAcuityPlanAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAcuityPlanAssignment) {
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

        func list() -> [RollingAcuityPlanAssignment] {
            var out: [RollingAcuityPlanAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAcuityPlanAssignmentStore() -> any RollingAcuityPlanAssignmentStore {
        return MemoryRollingAcuityPlanAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAcuityPlanAssignmentStore: RollingAcuityPlanAssignmentStore {
        var inner: MemoryRollingAcuityPlanAssignmentStore
        var cache: TTLCache<RollingAcuityPlanAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAcuityPlanAssignmentStore, cache: TTLCache<RollingAcuityPlanAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAcuityPlanAssignment? {
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

        func save(_ item: RollingAcuityPlanAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAcuityPlanAssignment] {
            return inner.list()
        }
    }

    static func newCachedRollingAcuityPlanAssignmentStore(_ inner: MemoryRollingAcuityPlanAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAcuityPlanAssignmentStore {
        return CachedRollingAcuityPlanAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling acuity plan assignments. Empty fields match all.
    final class RollingAcuityPlanAssignmentQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingAcuityPlanAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingAcuityPlanAssignment]) -> [RollingAcuityPlanAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAcuityPlanAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAcuityPlanAssignments(_ store: any RollingAcuityPlanAssignmentStore, query: RollingAcuityPlanAssignmentQuery) -> [RollingAcuityPlanAssignment] {
        return query.apply(store.list())
    }
}
