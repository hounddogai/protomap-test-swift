import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix rules by code.
    protocol SkillMixRuleStore {
        func find(_ code: String) -> SkillMixRule?
        func save(_ item: SkillMixRule)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixRuleStore: SkillMixRuleStore {
        var items: [String: SkillMixRule]
        var order: [String]

        init(items: [String: SkillMixRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixRule) {
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

        func list() -> [SkillMixRule] {
            var out: [SkillMixRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixRuleStore() -> any SkillMixRuleStore {
        return MemorySkillMixRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixRuleStore: SkillMixRuleStore {
        var inner: MemorySkillMixRuleStore
        var cache: TTLCache<SkillMixRule>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixRuleStore, cache: TTLCache<SkillMixRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixRule? {
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

        func save(_ item: SkillMixRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixRule] {
            return inner.list()
        }
    }

    static func newCachedSkillMixRuleStore(_ inner: MemorySkillMixRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixRuleStore {
        return CachedSkillMixRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix rules. Empty fields match all.
    final class SkillMixRuleQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixRule) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixRule]) -> [SkillMixRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixRules(_ store: any SkillMixRuleStore, query: SkillMixRuleQuery) -> [SkillMixRule] {
        return query.apply(store.list())
    }
}
