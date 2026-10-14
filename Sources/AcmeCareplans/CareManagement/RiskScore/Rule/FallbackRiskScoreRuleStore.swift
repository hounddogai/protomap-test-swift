import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback risk score rules by code.
    protocol FallbackRiskScoreRuleStore {
        func find(_ code: String) -> FallbackRiskScoreRule?
        func save(_ item: FallbackRiskScoreRule)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackRiskScoreRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackRiskScoreRuleStore: FallbackRiskScoreRuleStore {
        var items: [String: FallbackRiskScoreRule]
        var order: [String]

        init(items: [String: FallbackRiskScoreRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackRiskScoreRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackRiskScoreRule) {
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

        func list() -> [FallbackRiskScoreRule] {
            var out: [FallbackRiskScoreRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackRiskScoreRuleStore() -> any FallbackRiskScoreRuleStore {
        return MemoryFallbackRiskScoreRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackRiskScoreRuleStore: FallbackRiskScoreRuleStore {
        var inner: MemoryFallbackRiskScoreRuleStore
        var cache: TTLCache<FallbackRiskScoreRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackRiskScoreRuleStore, cache: TTLCache<FallbackRiskScoreRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackRiskScoreRule? {
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

        func save(_ item: FallbackRiskScoreRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackRiskScoreRule] {
            return inner.list()
        }
    }

    static func newCachedFallbackRiskScoreRuleStore(_ inner: MemoryFallbackRiskScoreRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackRiskScoreRuleStore {
        return CachedFallbackRiskScoreRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback risk score rules. Empty fields match all.
    final class FallbackRiskScoreRuleQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackRiskScoreRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackRiskScoreRule]) -> [FallbackRiskScoreRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackRiskScoreRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackRiskScoreRules(_ store: any FallbackRiskScoreRuleStore, query: FallbackRiskScoreRuleQuery) -> [FallbackRiskScoreRule] {
        return query.apply(store.list())
    }
}
