import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist audits by code.
    protocol WorklistAuditStore {
        func find(_ code: String) -> WorklistAudit?
        func save(_ item: WorklistAudit)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistAuditStore: WorklistAuditStore {
        var items: [String: WorklistAudit]
        var order: [String]

        init(items: [String: WorklistAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistAudit) {
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

        func list() -> [WorklistAudit] {
            var out: [WorklistAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistAuditStore() -> any WorklistAuditStore {
        return MemoryWorklistAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistAuditStore: WorklistAuditStore {
        var inner: MemoryWorklistAuditStore
        var cache: TTLCache<WorklistAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistAuditStore, cache: TTLCache<WorklistAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistAudit? {
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

        func save(_ item: WorklistAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistAudit] {
            return inner.list()
        }
    }

    static func newCachedWorklistAuditStore(_ inner: MemoryWorklistAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistAuditStore {
        return CachedWorklistAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist audits. Empty fields match all.
    final class WorklistAuditQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistAudit]) -> [WorklistAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistAudits(_ store: any WorklistAuditStore, query: WorklistAuditQuery) -> [WorklistAudit] {
        return query.apply(store.list())
    }
}
