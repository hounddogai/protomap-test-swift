import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps rolling isolation assignments by code.
    protocol RollingIsolationAssignmentStore {
        func find(_ code: String) -> RollingIsolationAssignment?
        func save(_ item: RollingIsolationAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RollingIsolationAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingIsolationAssignmentStore: RollingIsolationAssignmentStore {
        var items: [String: RollingIsolationAssignment]
        var order: [String]

        init(items: [String: RollingIsolationAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingIsolationAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingIsolationAssignment) {
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

        func list() -> [RollingIsolationAssignment] {
            var out: [RollingIsolationAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingIsolationAssignmentStore() -> any RollingIsolationAssignmentStore {
        return MemoryRollingIsolationAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingIsolationAssignmentStore: RollingIsolationAssignmentStore {
        var inner: MemoryRollingIsolationAssignmentStore
        var cache: TTLCache<RollingIsolationAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingIsolationAssignmentStore, cache: TTLCache<RollingIsolationAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingIsolationAssignment? {
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

        func save(_ item: RollingIsolationAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingIsolationAssignment] {
            return inner.list()
        }
    }

    static func newCachedRollingIsolationAssignmentStore(_ inner: MemoryRollingIsolationAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingIsolationAssignmentStore {
        return CachedRollingIsolationAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling isolation assignments. Empty fields match all.
    final class RollingIsolationAssignmentQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingIsolationAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [RollingIsolationAssignment]) -> [RollingIsolationAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingIsolationAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingIsolationAssignments(_ store: any RollingIsolationAssignmentStore, query: RollingIsolationAssignmentQuery) -> [RollingIsolationAssignment] {
        return query.apply(store.list())
    }
}
