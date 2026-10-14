import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps scheduled care protocol audits by code.
    protocol ScheduledCareProtocolAuditStore {
        func find(_ code: String) -> ScheduledCareProtocolAudit?
        func save(_ item: ScheduledCareProtocolAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCareProtocolAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCareProtocolAuditStore: ScheduledCareProtocolAuditStore {
        var items: [String: ScheduledCareProtocolAudit]
        var order: [String]

        init(items: [String: ScheduledCareProtocolAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCareProtocolAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCareProtocolAudit) {
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

        func list() -> [ScheduledCareProtocolAudit] {
            var out: [ScheduledCareProtocolAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCareProtocolAuditStore() -> any ScheduledCareProtocolAuditStore {
        return MemoryScheduledCareProtocolAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCareProtocolAuditStore: ScheduledCareProtocolAuditStore {
        var inner: MemoryScheduledCareProtocolAuditStore
        var cache: TTLCache<ScheduledCareProtocolAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCareProtocolAuditStore, cache: TTLCache<ScheduledCareProtocolAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCareProtocolAudit? {
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

        func save(_ item: ScheduledCareProtocolAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCareProtocolAudit] {
            return inner.list()
        }
    }

    static func newCachedScheduledCareProtocolAuditStore(_ inner: MemoryScheduledCareProtocolAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCareProtocolAuditStore {
        return CachedScheduledCareProtocolAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled care protocol audits. Empty fields match all.
    final class ScheduledCareProtocolAuditQuery {
        var channel: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minScore: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCareProtocolAudit) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ScheduledCareProtocolAudit]) -> [ScheduledCareProtocolAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCareProtocolAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCareProtocolAudits(_ store: any ScheduledCareProtocolAuditStore, query: ScheduledCareProtocolAuditQuery) -> [ScheduledCareProtocolAudit] {
        return query.apply(store.list())
    }
}
