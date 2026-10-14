import AcmePlatform
import Foundation

extension Consent {
    /// Keeps default proxy rules by code.
    protocol DefaultProxyRuleStore {
        func find(_ code: String) -> DefaultProxyRule?
        func save(_ item: DefaultProxyRule)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultProxyRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultProxyRuleStore: DefaultProxyRuleStore {
        var items: [String: DefaultProxyRule]
        var order: [String]

        init(items: [String: DefaultProxyRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultProxyRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultProxyRule) {
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

        func list() -> [DefaultProxyRule] {
            var out: [DefaultProxyRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultProxyRuleStore() -> any DefaultProxyRuleStore {
        return MemoryDefaultProxyRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultProxyRuleStore: DefaultProxyRuleStore {
        var inner: MemoryDefaultProxyRuleStore
        var cache: TTLCache<DefaultProxyRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultProxyRuleStore, cache: TTLCache<DefaultProxyRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultProxyRule? {
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

        func save(_ item: DefaultProxyRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultProxyRule] {
            return inner.list()
        }
    }

    static func newCachedDefaultProxyRuleStore(_ inner: MemoryDefaultProxyRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultProxyRuleStore {
        return CachedDefaultProxyRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default proxy rules. Empty fields match all.
    final class DefaultProxyRuleQuery {
        var source: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultProxyRule) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [DefaultProxyRule]) -> [DefaultProxyRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultProxyRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultProxyRules(_ store: any DefaultProxyRuleStore, query: DefaultProxyRuleQuery) -> [DefaultProxyRule] {
        return query.apply(store.list())
    }
}
