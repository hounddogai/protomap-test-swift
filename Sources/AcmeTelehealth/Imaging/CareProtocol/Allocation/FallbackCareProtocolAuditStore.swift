import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps fallback care protocol audits by code.
    protocol FallbackCareProtocolAuditStore {
        func find(_ code: String) -> FallbackCareProtocolAudit?
        func save(_ item: FallbackCareProtocolAudit)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCareProtocolAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCareProtocolAuditStore: FallbackCareProtocolAuditStore {
        var items: [String: FallbackCareProtocolAudit]
        var order: [String]

        init(items: [String: FallbackCareProtocolAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCareProtocolAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCareProtocolAudit) {
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

        func list() -> [FallbackCareProtocolAudit] {
            var out: [FallbackCareProtocolAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCareProtocolAuditStore() -> any FallbackCareProtocolAuditStore {
        return MemoryFallbackCareProtocolAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCareProtocolAuditStore: FallbackCareProtocolAuditStore {
        var inner: MemoryFallbackCareProtocolAuditStore
        var cache: TTLCache<FallbackCareProtocolAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCareProtocolAuditStore, cache: TTLCache<FallbackCareProtocolAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCareProtocolAudit? {
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

        func save(_ item: FallbackCareProtocolAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCareProtocolAudit] {
            return inner.list()
        }
    }

    static func newCachedFallbackCareProtocolAuditStore(_ inner: MemoryFallbackCareProtocolAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCareProtocolAuditStore {
        return CachedFallbackCareProtocolAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback care protocol audits. Empty fields match all.
    final class FallbackCareProtocolAuditQuery {
        var title: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minSequence: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCareProtocolAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [FallbackCareProtocolAudit]) -> [FallbackCareProtocolAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCareProtocolAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCareProtocolAudits(_ store: any FallbackCareProtocolAuditStore, query: FallbackCareProtocolAuditQuery) -> [FallbackCareProtocolAudit] {
        return query.apply(store.list())
    }
}
