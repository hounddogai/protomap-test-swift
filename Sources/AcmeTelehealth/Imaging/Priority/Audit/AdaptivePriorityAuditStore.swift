import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps adaptive priority audits by code.
    protocol AdaptivePriorityAuditStore {
        func find(_ code: String) -> AdaptivePriorityAudit?
        func save(_ item: AdaptivePriorityAudit)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptivePriorityAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptivePriorityAuditStore: AdaptivePriorityAuditStore {
        var items: [String: AdaptivePriorityAudit]
        var order: [String]

        init(items: [String: AdaptivePriorityAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptivePriorityAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptivePriorityAudit) {
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

        func list() -> [AdaptivePriorityAudit] {
            var out: [AdaptivePriorityAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptivePriorityAuditStore() -> any AdaptivePriorityAuditStore {
        return MemoryAdaptivePriorityAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptivePriorityAuditStore: AdaptivePriorityAuditStore {
        var inner: MemoryAdaptivePriorityAuditStore
        var cache: TTLCache<AdaptivePriorityAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptivePriorityAuditStore, cache: TTLCache<AdaptivePriorityAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptivePriorityAudit? {
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

        func save(_ item: AdaptivePriorityAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptivePriorityAudit] {
            return inner.list()
        }
    }

    static func newCachedAdaptivePriorityAuditStore(_ inner: MemoryAdaptivePriorityAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptivePriorityAuditStore {
        return CachedAdaptivePriorityAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive priority audits. Empty fields match all.
    final class AdaptivePriorityAuditQuery {
        var channel: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRetries: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptivePriorityAudit) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptivePriorityAudit]) -> [AdaptivePriorityAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptivePriorityAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptivePriorityAudits(_ store: any AdaptivePriorityAuditStore, query: AdaptivePriorityAuditQuery) -> [AdaptivePriorityAudit] {
        return query.apply(store.list())
    }
}
