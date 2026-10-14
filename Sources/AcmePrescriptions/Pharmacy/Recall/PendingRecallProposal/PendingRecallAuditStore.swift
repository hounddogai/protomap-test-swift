import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending recall audits by code.
    protocol PendingRecallAuditStore {
        func find(_ code: String) -> PendingRecallAudit?
        func save(_ item: PendingRecallAudit)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRecallAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRecallAuditStore: PendingRecallAuditStore {
        var items: [String: PendingRecallAudit]
        var order: [String]

        init(items: [String: PendingRecallAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRecallAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRecallAudit) {
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

        func list() -> [PendingRecallAudit] {
            var out: [PendingRecallAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRecallAuditStore() -> any PendingRecallAuditStore {
        return MemoryPendingRecallAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRecallAuditStore: PendingRecallAuditStore {
        var inner: MemoryPendingRecallAuditStore
        var cache: TTLCache<PendingRecallAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRecallAuditStore, cache: TTLCache<PendingRecallAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRecallAudit? {
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

        func save(_ item: PendingRecallAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRecallAudit] {
            return inner.list()
        }
    }

    static func newCachedPendingRecallAuditStore(_ inner: MemoryPendingRecallAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRecallAuditStore {
        return CachedPendingRecallAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending recall audits. Empty fields match all.
    final class PendingRecallAuditQuery {
        var ward: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRetries: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRecallAudit) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [PendingRecallAudit]) -> [PendingRecallAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRecallAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRecallAudits(_ store: any PendingRecallAuditStore, query: PendingRecallAuditQuery) -> [PendingRecallAudit] {
        return query.apply(store.list())
    }
}
