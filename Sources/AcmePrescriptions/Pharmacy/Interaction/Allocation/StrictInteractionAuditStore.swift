import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict interaction audits by code.
    protocol StrictInteractionAuditStore {
        func find(_ code: String) -> StrictInteractionAudit?
        func save(_ item: StrictInteractionAudit)
        func remove(_ code: String) -> Bool
        func list() -> [StrictInteractionAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictInteractionAuditStore: StrictInteractionAuditStore {
        var items: [String: StrictInteractionAudit]
        var order: [String]

        init(items: [String: StrictInteractionAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictInteractionAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictInteractionAudit) {
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

        func list() -> [StrictInteractionAudit] {
            var out: [StrictInteractionAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictInteractionAuditStore() -> any StrictInteractionAuditStore {
        return MemoryStrictInteractionAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictInteractionAuditStore: StrictInteractionAuditStore {
        var inner: MemoryStrictInteractionAuditStore
        var cache: TTLCache<StrictInteractionAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictInteractionAuditStore, cache: TTLCache<StrictInteractionAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictInteractionAudit? {
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

        func save(_ item: StrictInteractionAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictInteractionAudit] {
            return inner.list()
        }
    }

    static func newCachedStrictInteractionAuditStore(_ inner: MemoryStrictInteractionAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictInteractionAuditStore {
        return CachedStrictInteractionAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict interaction audits. Empty fields match all.
    final class StrictInteractionAuditQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictInteractionAudit) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictInteractionAudit]) -> [StrictInteractionAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictInteractionAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictInteractionAudits(_ store: any StrictInteractionAuditStore, query: StrictInteractionAuditQuery) -> [StrictInteractionAudit] {
        return query.apply(store.list())
    }
}
