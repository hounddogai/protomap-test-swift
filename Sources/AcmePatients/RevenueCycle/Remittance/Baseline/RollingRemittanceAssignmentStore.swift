import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps rolling remittance assignments by code.
    protocol RollingRemittanceAssignmentStore {
        func find(_ code: String) -> RollingRemittanceAssignment?
        func save(_ item: RollingRemittanceAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RollingRemittanceAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingRemittanceAssignmentStore: RollingRemittanceAssignmentStore {
        var items: [String: RollingRemittanceAssignment]
        var order: [String]

        init(items: [String: RollingRemittanceAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingRemittanceAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingRemittanceAssignment) {
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

        func list() -> [RollingRemittanceAssignment] {
            var out: [RollingRemittanceAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingRemittanceAssignmentStore() -> any RollingRemittanceAssignmentStore {
        return MemoryRollingRemittanceAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingRemittanceAssignmentStore: RollingRemittanceAssignmentStore {
        var inner: MemoryRollingRemittanceAssignmentStore
        var cache: TTLCache<RollingRemittanceAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingRemittanceAssignmentStore, cache: TTLCache<RollingRemittanceAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingRemittanceAssignment? {
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

        func save(_ item: RollingRemittanceAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingRemittanceAssignment] {
            return inner.list()
        }
    }

    static func newCachedRollingRemittanceAssignmentStore(_ inner: MemoryRollingRemittanceAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingRemittanceAssignmentStore {
        return CachedRollingRemittanceAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling remittance assignments. Empty fields match all.
    final class RollingRemittanceAssignmentQuery {
        var category: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRevision: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingRemittanceAssignment) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingRemittanceAssignment]) -> [RollingRemittanceAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingRemittanceAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingRemittanceAssignments(_ store: any RollingRemittanceAssignmentStore, query: RollingRemittanceAssignmentQuery) -> [RollingRemittanceAssignment] {
        return query.apply(store.list())
    }
}
