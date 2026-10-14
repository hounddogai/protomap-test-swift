import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps default network rules by code.
    protocol DefaultNetworkRuleStore {
        func find(_ code: String) -> DefaultNetworkRule?
        func save(_ item: DefaultNetworkRule)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultNetworkRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultNetworkRuleStore: DefaultNetworkRuleStore {
        var items: [String: DefaultNetworkRule]
        var order: [String]

        init(items: [String: DefaultNetworkRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultNetworkRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultNetworkRule) {
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

        func list() -> [DefaultNetworkRule] {
            var out: [DefaultNetworkRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultNetworkRuleStore() -> any DefaultNetworkRuleStore {
        return MemoryDefaultNetworkRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultNetworkRuleStore: DefaultNetworkRuleStore {
        var inner: MemoryDefaultNetworkRuleStore
        var cache: TTLCache<DefaultNetworkRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultNetworkRuleStore, cache: TTLCache<DefaultNetworkRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultNetworkRule? {
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

        func save(_ item: DefaultNetworkRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultNetworkRule] {
            return inner.list()
        }
    }

    static func newCachedDefaultNetworkRuleStore(_ inner: MemoryDefaultNetworkRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultNetworkRuleStore {
        return CachedDefaultNetworkRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default network rules. Empty fields match all.
    final class DefaultNetworkRuleQuery {
        var country: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minScore: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultNetworkRule) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultNetworkRule]) -> [DefaultNetworkRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultNetworkRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultNetworkRules(_ store: any DefaultNetworkRuleStore, query: DefaultNetworkRuleQuery) -> [DefaultNetworkRule] {
        return query.apply(store.list())
    }
}
