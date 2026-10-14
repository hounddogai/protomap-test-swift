import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled network rules by code.
    protocol ScheduledNetworkRuleStore {
        func find(_ code: String) -> ScheduledNetworkRule?
        func save(_ item: ScheduledNetworkRule)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledNetworkRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledNetworkRuleStore: ScheduledNetworkRuleStore {
        var items: [String: ScheduledNetworkRule]
        var order: [String]

        init(items: [String: ScheduledNetworkRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledNetworkRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledNetworkRule) {
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

        func list() -> [ScheduledNetworkRule] {
            var out: [ScheduledNetworkRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledNetworkRuleStore() -> any ScheduledNetworkRuleStore {
        return MemoryScheduledNetworkRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledNetworkRuleStore: ScheduledNetworkRuleStore {
        var inner: MemoryScheduledNetworkRuleStore
        var cache: TTLCache<ScheduledNetworkRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledNetworkRuleStore, cache: TTLCache<ScheduledNetworkRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledNetworkRule? {
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

        func save(_ item: ScheduledNetworkRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledNetworkRule] {
            return inner.list()
        }
    }

    static func newCachedScheduledNetworkRuleStore(_ inner: MemoryScheduledNetworkRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledNetworkRuleStore {
        return CachedScheduledNetworkRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled network rules. Empty fields match all.
    final class ScheduledNetworkRuleQuery {
        var ward: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRefills: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledNetworkRule) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledNetworkRule]) -> [ScheduledNetworkRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledNetworkRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledNetworkRules(_ store: any ScheduledNetworkRuleStore, query: ScheduledNetworkRuleQuery) -> [ScheduledNetworkRule] {
        return query.apply(store.list())
    }
}
