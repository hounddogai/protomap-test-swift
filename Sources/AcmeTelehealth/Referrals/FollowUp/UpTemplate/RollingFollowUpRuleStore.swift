import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps rolling follow up rules by code.
    protocol RollingFollowUpRuleStore {
        func find(_ code: String) -> RollingFollowUpRule?
        func save(_ item: RollingFollowUpRule)
        func remove(_ code: String) -> Bool
        func list() -> [RollingFollowUpRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingFollowUpRuleStore: RollingFollowUpRuleStore {
        var items: [String: RollingFollowUpRule]
        var order: [String]

        init(items: [String: RollingFollowUpRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingFollowUpRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingFollowUpRule) {
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

        func list() -> [RollingFollowUpRule] {
            var out: [RollingFollowUpRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingFollowUpRuleStore() -> any RollingFollowUpRuleStore {
        return MemoryRollingFollowUpRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingFollowUpRuleStore: RollingFollowUpRuleStore {
        var inner: MemoryRollingFollowUpRuleStore
        var cache: TTLCache<RollingFollowUpRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingFollowUpRuleStore, cache: TTLCache<RollingFollowUpRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingFollowUpRule? {
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

        func save(_ item: RollingFollowUpRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingFollowUpRule] {
            return inner.list()
        }
    }

    static func newCachedRollingFollowUpRuleStore(_ inner: MemoryRollingFollowUpRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingFollowUpRuleStore {
        return CachedRollingFollowUpRuleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling follow up rules. Empty fields match all.
    final class RollingFollowUpRuleQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingFollowUpRule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingFollowUpRule]) -> [RollingFollowUpRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingFollowUpRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingFollowUpRules(_ store: any RollingFollowUpRuleStore, query: RollingFollowUpRuleQuery) -> [RollingFollowUpRule] {
        return query.apply(store.list())
    }
}
