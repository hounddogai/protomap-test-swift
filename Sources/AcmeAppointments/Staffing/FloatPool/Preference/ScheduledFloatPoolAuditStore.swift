import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps scheduled float pool audits by code.
    protocol ScheduledFloatPoolAuditStore {
        func find(_ code: String) -> ScheduledFloatPoolAudit?
        func save(_ item: ScheduledFloatPoolAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledFloatPoolAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledFloatPoolAuditStore: ScheduledFloatPoolAuditStore {
        var items: [String: ScheduledFloatPoolAudit]
        var order: [String]

        init(items: [String: ScheduledFloatPoolAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledFloatPoolAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledFloatPoolAudit) {
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

        func list() -> [ScheduledFloatPoolAudit] {
            var out: [ScheduledFloatPoolAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledFloatPoolAuditStore() -> any ScheduledFloatPoolAuditStore {
        return MemoryScheduledFloatPoolAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledFloatPoolAuditStore: ScheduledFloatPoolAuditStore {
        var inner: MemoryScheduledFloatPoolAuditStore
        var cache: TTLCache<ScheduledFloatPoolAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledFloatPoolAuditStore, cache: TTLCache<ScheduledFloatPoolAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledFloatPoolAudit? {
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

        func save(_ item: ScheduledFloatPoolAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledFloatPoolAudit] {
            return inner.list()
        }
    }

    static func newCachedScheduledFloatPoolAuditStore(_ inner: MemoryScheduledFloatPoolAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledFloatPoolAuditStore {
        return CachedScheduledFloatPoolAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled float pool audits. Empty fields match all.
    final class ScheduledFloatPoolAuditQuery {
        var channel: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledFloatPoolAudit) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ScheduledFloatPoolAudit]) -> [ScheduledFloatPoolAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledFloatPoolAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledFloatPoolAudits(_ store: any ScheduledFloatPoolAuditStore, query: ScheduledFloatPoolAuditQuery) -> [ScheduledFloatPoolAudit] {
        return query.apply(store.list())
    }
}
