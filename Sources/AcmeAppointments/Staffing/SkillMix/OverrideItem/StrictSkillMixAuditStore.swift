import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict skill mix audits by code.
    protocol StrictSkillMixAuditStore {
        func find(_ code: String) -> StrictSkillMixAudit?
        func save(_ item: StrictSkillMixAudit)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSkillMixAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSkillMixAuditStore: StrictSkillMixAuditStore {
        var items: [String: StrictSkillMixAudit]
        var order: [String]

        init(items: [String: StrictSkillMixAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSkillMixAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSkillMixAudit) {
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

        func list() -> [StrictSkillMixAudit] {
            var out: [StrictSkillMixAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSkillMixAuditStore() -> any StrictSkillMixAuditStore {
        return MemoryStrictSkillMixAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSkillMixAuditStore: StrictSkillMixAuditStore {
        var inner: MemoryStrictSkillMixAuditStore
        var cache: TTLCache<StrictSkillMixAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSkillMixAuditStore, cache: TTLCache<StrictSkillMixAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSkillMixAudit? {
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

        func save(_ item: StrictSkillMixAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSkillMixAudit] {
            return inner.list()
        }
    }

    static func newCachedStrictSkillMixAuditStore(_ inner: MemoryStrictSkillMixAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSkillMixAuditStore {
        return CachedStrictSkillMixAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict skill mix audits. Empty fields match all.
    final class StrictSkillMixAuditQuery {
        var source: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCost: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSkillMixAudit) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSkillMixAudit]) -> [StrictSkillMixAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSkillMixAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSkillMixAudits(_ store: any StrictSkillMixAuditStore, query: StrictSkillMixAuditQuery) -> [StrictSkillMixAudit] {
        return query.apply(store.list())
    }
}
