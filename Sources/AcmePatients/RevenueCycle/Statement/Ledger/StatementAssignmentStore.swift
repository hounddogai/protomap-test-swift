import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement assignments by code.
    protocol StatementAssignmentStore {
        func find(_ code: String) -> StatementAssignment?
        func save(_ item: StatementAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [StatementAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementAssignmentStore: StatementAssignmentStore {
        var items: [String: StatementAssignment]
        var order: [String]

        init(items: [String: StatementAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementAssignment) {
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

        func list() -> [StatementAssignment] {
            var out: [StatementAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementAssignmentStore() -> any StatementAssignmentStore {
        return MemoryStatementAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementAssignmentStore: StatementAssignmentStore {
        var inner: MemoryStatementAssignmentStore
        var cache: TTLCache<StatementAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementAssignmentStore, cache: TTLCache<StatementAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementAssignment? {
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

        func save(_ item: StatementAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementAssignment] {
            return inner.list()
        }
    }

    static func newCachedStatementAssignmentStore(_ inner: MemoryStatementAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementAssignmentStore {
        return CachedStatementAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement assignments. Empty fields match all.
    final class StatementAssignmentQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementAssignment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementAssignment]) -> [StatementAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementAssignments(_ store: any StatementAssignmentStore, query: StatementAssignmentQuery) -> [StatementAssignment] {
        return query.apply(store.list())
    }
}
