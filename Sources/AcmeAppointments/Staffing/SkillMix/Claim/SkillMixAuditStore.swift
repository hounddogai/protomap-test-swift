import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix audits by code.
    protocol SkillMixAuditStore {
        func find(_ code: String) -> SkillMixAudit?
        func save(_ item: SkillMixAudit)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixAuditStore: SkillMixAuditStore {
        var items: [String: SkillMixAudit]
        var order: [String]

        init(items: [String: SkillMixAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixAudit) {
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

        func list() -> [SkillMixAudit] {
            var out: [SkillMixAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixAuditStore() -> any SkillMixAuditStore {
        return MemorySkillMixAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixAuditStore: SkillMixAuditStore {
        var inner: MemorySkillMixAuditStore
        var cache: TTLCache<SkillMixAudit>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixAuditStore, cache: TTLCache<SkillMixAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixAudit? {
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

        func save(_ item: SkillMixAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixAudit] {
            return inner.list()
        }
    }

    static func newCachedSkillMixAuditStore(_ inner: MemorySkillMixAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixAuditStore {
        return CachedSkillMixAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix audits. Empty fields match all.
    final class SkillMixAuditQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixAudit]) -> [SkillMixAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixAudits(_ store: any SkillMixAuditStore, query: SkillMixAuditQuery) -> [SkillMixAudit] {
        return query.apply(store.list())
    }
}
