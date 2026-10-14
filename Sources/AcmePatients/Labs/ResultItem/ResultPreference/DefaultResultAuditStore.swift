import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default result audits by code.
    protocol DefaultResultAuditStore {
        func find(_ code: String) -> DefaultResultAudit?
        func save(_ item: DefaultResultAudit)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultResultAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultResultAuditStore: DefaultResultAuditStore {
        var items: [String: DefaultResultAudit]
        var order: [String]

        init(items: [String: DefaultResultAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultResultAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultResultAudit) {
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

        func list() -> [DefaultResultAudit] {
            var out: [DefaultResultAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultResultAuditStore() -> any DefaultResultAuditStore {
        return MemoryDefaultResultAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultResultAuditStore: DefaultResultAuditStore {
        var inner: MemoryDefaultResultAuditStore
        var cache: TTLCache<DefaultResultAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultResultAuditStore, cache: TTLCache<DefaultResultAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultResultAudit? {
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

        func save(_ item: DefaultResultAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultResultAudit] {
            return inner.list()
        }
    }

    static func newCachedDefaultResultAuditStore(_ inner: MemoryDefaultResultAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultResultAuditStore {
        return CachedDefaultResultAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default result audits. Empty fields match all.
    final class DefaultResultAuditQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultResultAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultResultAudit]) -> [DefaultResultAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultResultAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultResultAudits(_ store: any DefaultResultAuditStore, query: DefaultResultAuditQuery) -> [DefaultResultAudit] {
        return query.apply(store.list())
    }
}
