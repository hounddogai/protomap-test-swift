import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps rolling discharge plan rules by code.
    protocol RollingDischargePlanRuleStore {
        func find(_ code: String) -> RollingDischargePlanRule?
        func save(_ item: RollingDischargePlanRule)
        func remove(_ code: String) -> Bool
        func list() -> [RollingDischargePlanRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingDischargePlanRuleStore: RollingDischargePlanRuleStore {
        var items: [String: RollingDischargePlanRule]
        var order: [String]

        init(items: [String: RollingDischargePlanRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingDischargePlanRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingDischargePlanRule) {
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

        func list() -> [RollingDischargePlanRule] {
            var out: [RollingDischargePlanRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingDischargePlanRuleStore() -> any RollingDischargePlanRuleStore {
        return MemoryRollingDischargePlanRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingDischargePlanRuleStore: RollingDischargePlanRuleStore {
        var inner: MemoryRollingDischargePlanRuleStore
        var cache: TTLCache<RollingDischargePlanRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingDischargePlanRuleStore, cache: TTLCache<RollingDischargePlanRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingDischargePlanRule? {
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

        func save(_ item: RollingDischargePlanRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingDischargePlanRule] {
            return inner.list()
        }
    }

    static func newCachedRollingDischargePlanRuleStore(_ inner: MemoryRollingDischargePlanRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingDischargePlanRuleStore {
        return CachedRollingDischargePlanRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling discharge plan rules. Empty fields match all.
    final class RollingDischargePlanRuleQuery {
        var channel: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingDischargePlanRule) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingDischargePlanRule]) -> [RollingDischargePlanRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingDischargePlanRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingDischargePlanRules(_ store: any RollingDischargePlanRuleStore, query: RollingDischargePlanRuleQuery) -> [RollingDischargePlanRule] {
        return query.apply(store.list())
    }
}
