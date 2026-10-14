import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task audits by code.
    protocol TaskAuditStore {
        func find(_ code: String) -> TaskAudit?
        func save(_ item: TaskAudit)
        func remove(_ code: String) -> Bool
        func list() -> [TaskAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskAuditStore: TaskAuditStore {
        var items: [String: TaskAudit]
        var order: [String]

        init(items: [String: TaskAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskAudit) {
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

        func list() -> [TaskAudit] {
            var out: [TaskAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskAuditStore() -> any TaskAuditStore {
        return MemoryTaskAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskAuditStore: TaskAuditStore {
        var inner: MemoryTaskAuditStore
        var cache: TTLCache<TaskAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskAuditStore, cache: TTLCache<TaskAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskAudit? {
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

        func save(_ item: TaskAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskAudit] {
            return inner.list()
        }
    }

    static func newCachedTaskAuditStore(_ inner: MemoryTaskAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskAuditStore {
        return CachedTaskAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task audits. Empty fields match all.
    final class TaskAuditQuery {
        var ward: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minAmount: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskAudit) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskAudit]) -> [TaskAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskAudits(_ store: any TaskAuditStore, query: TaskAuditQuery) -> [TaskAudit] {
        return query.apply(store.list())
    }
}
