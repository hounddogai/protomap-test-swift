import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal audits by code.
    protocol GoalAuditStore {
        func find(_ code: String) -> GoalAudit?
        func save(_ item: GoalAudit)
        func remove(_ code: String) -> Bool
        func list() -> [GoalAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalAuditStore: GoalAuditStore {
        var items: [String: GoalAudit]
        var order: [String]

        init(items: [String: GoalAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalAudit) {
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

        func list() -> [GoalAudit] {
            var out: [GoalAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalAuditStore() -> any GoalAuditStore {
        return MemoryGoalAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalAuditStore: GoalAuditStore {
        var inner: MemoryGoalAuditStore
        var cache: TTLCache<GoalAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalAuditStore, cache: TTLCache<GoalAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalAudit? {
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

        func save(_ item: GoalAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalAudit] {
            return inner.list()
        }
    }

    static func newCachedGoalAuditStore(_ inner: MemoryGoalAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalAuditStore {
        return CachedGoalAuditStore(inner: inner, cache: newTTLCache(64, ttl: ttl, clock: clock), hits: 0, misses: 0)
    }

    /// Selects goal audits. Empty fields match all.
    final class GoalAuditQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalAudit) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalAudit]) -> [GoalAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalAudits(_ store: any GoalAuditStore, query: GoalAuditQuery) -> [GoalAudit] {
        return query.apply(store.list())
    }
}
