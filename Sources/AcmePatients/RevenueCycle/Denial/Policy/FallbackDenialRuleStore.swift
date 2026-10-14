import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback denial rules by code.
    protocol FallbackDenialRuleStore {
        func find(_ code: String) -> FallbackDenialRule?
        func save(_ item: FallbackDenialRule)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDenialRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDenialRuleStore: FallbackDenialRuleStore {
        var items: [String: FallbackDenialRule]
        var order: [String]

        init(items: [String: FallbackDenialRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDenialRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDenialRule) {
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

        func list() -> [FallbackDenialRule] {
            var out: [FallbackDenialRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDenialRuleStore() -> any FallbackDenialRuleStore {
        return MemoryFallbackDenialRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDenialRuleStore: FallbackDenialRuleStore {
        var inner: MemoryFallbackDenialRuleStore
        var cache: TTLCache<FallbackDenialRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDenialRuleStore, cache: TTLCache<FallbackDenialRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDenialRule? {
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

        func save(_ item: FallbackDenialRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDenialRule] {
            return inner.list()
        }
    }

    static func newCachedFallbackDenialRuleStore(_ inner: MemoryFallbackDenialRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDenialRuleStore {
        return CachedFallbackDenialRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback denial rules. Empty fields match all.
    final class FallbackDenialRuleQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDenialRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [FallbackDenialRule]) -> [FallbackDenialRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDenialRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDenialRules(_ store: any FallbackDenialRuleStore, query: FallbackDenialRuleQuery) -> [FallbackDenialRule] {
        return query.apply(store.list())
    }
}
