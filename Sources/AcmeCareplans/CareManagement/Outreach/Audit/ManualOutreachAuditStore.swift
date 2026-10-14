import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual outreach audits by code.
    protocol ManualOutreachAuditStore {
        func find(_ code: String) -> ManualOutreachAudit?
        func save(_ item: ManualOutreachAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ManualOutreachAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualOutreachAuditStore: ManualOutreachAuditStore {
        var items: [String: ManualOutreachAudit]
        var order: [String]

        init(items: [String: ManualOutreachAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualOutreachAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualOutreachAudit) {
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

        func list() -> [ManualOutreachAudit] {
            var out: [ManualOutreachAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualOutreachAuditStore() -> any ManualOutreachAuditStore {
        return MemoryManualOutreachAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualOutreachAuditStore: ManualOutreachAuditStore {
        var inner: MemoryManualOutreachAuditStore
        var cache: TTLCache<ManualOutreachAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualOutreachAuditStore, cache: TTLCache<ManualOutreachAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualOutreachAudit? {
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

        func save(_ item: ManualOutreachAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualOutreachAudit] {
            return inner.list()
        }
    }

    static func newCachedManualOutreachAuditStore(_ inner: MemoryManualOutreachAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualOutreachAuditStore {
        return CachedManualOutreachAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual outreach audits. Empty fields match all.
    final class ManualOutreachAuditQuery {
        var label: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualOutreachAudit) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualOutreachAudit]) -> [ManualOutreachAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualOutreachAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualOutreachAudits(_ store: any ManualOutreachAuditStore, query: ManualOutreachAuditQuery) -> [ManualOutreachAudit] {
        return query.apply(store.list())
    }
}
