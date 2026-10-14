import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range audits by code.
    protocol ReferenceRangeAuditStore {
        func find(_ code: String) -> ReferenceRangeAudit?
        func save(_ item: ReferenceRangeAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeAuditStore: ReferenceRangeAuditStore {
        var items: [String: ReferenceRangeAudit]
        var order: [String]

        init(items: [String: ReferenceRangeAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeAudit) {
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

        func list() -> [ReferenceRangeAudit] {
            var out: [ReferenceRangeAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeAuditStore() -> any ReferenceRangeAuditStore {
        return MemoryReferenceRangeAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeAuditStore: ReferenceRangeAuditStore {
        var inner: MemoryReferenceRangeAuditStore
        var cache: TTLCache<ReferenceRangeAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeAuditStore, cache: TTLCache<ReferenceRangeAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeAudit? {
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

        func save(_ item: ReferenceRangeAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeAudit] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeAuditStore(_ inner: MemoryReferenceRangeAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeAuditStore {
        return CachedReferenceRangeAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range audits. Empty fields match all.
    final class ReferenceRangeAuditQuery {
        var region: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRetries: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeAudit) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [ReferenceRangeAudit]) -> [ReferenceRangeAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeAudits(_ store: any ReferenceRangeAuditStore, query: ReferenceRangeAuditQuery) -> [ReferenceRangeAudit] {
        return query.apply(store.list())
    }
}
