import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps scheduled modality audits by code.
    protocol ScheduledModalityAuditStore {
        func find(_ code: String) -> ScheduledModalityAudit?
        func save(_ item: ScheduledModalityAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledModalityAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledModalityAuditStore: ScheduledModalityAuditStore {
        var items: [String: ScheduledModalityAudit]
        var order: [String]

        init(items: [String: ScheduledModalityAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledModalityAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledModalityAudit) {
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

        func list() -> [ScheduledModalityAudit] {
            var out: [ScheduledModalityAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledModalityAuditStore() -> any ScheduledModalityAuditStore {
        return MemoryScheduledModalityAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledModalityAuditStore: ScheduledModalityAuditStore {
        var inner: MemoryScheduledModalityAuditStore
        var cache: TTLCache<ScheduledModalityAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledModalityAuditStore, cache: TTLCache<ScheduledModalityAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledModalityAudit? {
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

        func save(_ item: ScheduledModalityAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledModalityAudit] {
            return inner.list()
        }
    }

    static func newCachedScheduledModalityAuditStore(_ inner: MemoryScheduledModalityAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledModalityAuditStore {
        return CachedScheduledModalityAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled modality audits. Empty fields match all.
    final class ScheduledModalityAuditQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledModalityAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledModalityAudit]) -> [ScheduledModalityAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledModalityAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledModalityAudits(_ store: any ScheduledModalityAuditStore, query: ScheduledModalityAuditQuery) -> [ScheduledModalityAudit] {
        return query.apply(store.list())
    }
}
