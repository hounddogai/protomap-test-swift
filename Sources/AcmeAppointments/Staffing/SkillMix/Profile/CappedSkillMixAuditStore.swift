import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps capped skill mix audits by code.
    protocol CappedSkillMixAuditStore {
        func find(_ code: String) -> CappedSkillMixAudit?
        func save(_ item: CappedSkillMixAudit)
        func remove(_ code: String) -> Bool
        func list() -> [CappedSkillMixAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedSkillMixAuditStore: CappedSkillMixAuditStore {
        var items: [String: CappedSkillMixAudit]
        var order: [String]

        init(items: [String: CappedSkillMixAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedSkillMixAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedSkillMixAudit) {
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

        func list() -> [CappedSkillMixAudit] {
            var out: [CappedSkillMixAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedSkillMixAuditStore() -> any CappedSkillMixAuditStore {
        return MemoryCappedSkillMixAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedSkillMixAuditStore: CappedSkillMixAuditStore {
        var inner: MemoryCappedSkillMixAuditStore
        var cache: TTLCache<CappedSkillMixAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedSkillMixAuditStore, cache: TTLCache<CappedSkillMixAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedSkillMixAudit? {
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

        func save(_ item: CappedSkillMixAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedSkillMixAudit] {
            return inner.list()
        }
    }

    static func newCachedCappedSkillMixAuditStore(_ inner: MemoryCappedSkillMixAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedSkillMixAuditStore {
        return CachedCappedSkillMixAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped skill mix audits. Empty fields match all.
    final class CappedSkillMixAuditQuery {
        var channel: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minSequence: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedSkillMixAudit) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [CappedSkillMixAudit]) -> [CappedSkillMixAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedSkillMixAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedSkillMixAudits(_ store: any CappedSkillMixAuditStore, query: CappedSkillMixAuditQuery) -> [CappedSkillMixAudit] {
        return query.apply(store.list())
    }
}
