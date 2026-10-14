import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps rolling modality assignments by code.
    protocol RollingModalityAssignmentStore {
        func find(_ code: String) -> RollingModalityAssignment?
        func save(_ item: RollingModalityAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RollingModalityAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingModalityAssignmentStore: RollingModalityAssignmentStore {
        var items: [String: RollingModalityAssignment]
        var order: [String]

        init(items: [String: RollingModalityAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingModalityAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingModalityAssignment) {
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

        func list() -> [RollingModalityAssignment] {
            var out: [RollingModalityAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingModalityAssignmentStore() -> any RollingModalityAssignmentStore {
        return MemoryRollingModalityAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingModalityAssignmentStore: RollingModalityAssignmentStore {
        var inner: MemoryRollingModalityAssignmentStore
        var cache: TTLCache<RollingModalityAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingModalityAssignmentStore, cache: TTLCache<RollingModalityAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingModalityAssignment? {
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

        func save(_ item: RollingModalityAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingModalityAssignment] {
            return inner.list()
        }
    }

    static func newCachedRollingModalityAssignmentStore(_ inner: MemoryRollingModalityAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingModalityAssignmentStore {
        return CachedRollingModalityAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling modality assignments. Empty fields match all.
    final class RollingModalityAssignmentQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingModalityAssignment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingModalityAssignment]) -> [RollingModalityAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingModalityAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingModalityAssignments(_ store: any RollingModalityAssignmentStore, query: RollingModalityAssignmentQuery) -> [RollingModalityAssignment] {
        return query.apply(store.list())
    }
}
