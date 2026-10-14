import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score rules by code.
    protocol RiskScoreRuleStore {
        func find(_ code: String) -> RiskScoreRule?
        func save(_ item: RiskScoreRule)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreRuleStore: RiskScoreRuleStore {
        var items: [String: RiskScoreRule]
        var order: [String]

        init(items: [String: RiskScoreRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreRule) {
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

        func list() -> [RiskScoreRule] {
            var out: [RiskScoreRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreRuleStore() -> any RiskScoreRuleStore {
        return MemoryRiskScoreRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreRuleStore: RiskScoreRuleStore {
        var inner: MemoryRiskScoreRuleStore
        var cache: TTLCache<RiskScoreRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreRuleStore, cache: TTLCache<RiskScoreRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreRule? {
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

        func save(_ item: RiskScoreRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreRule] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreRuleStore(_ inner: MemoryRiskScoreRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreRuleStore {
        return CachedRiskScoreRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score rules. Empty fields match all.
    final class RiskScoreRuleQuery {
        var unit: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreRule) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreRule]) -> [RiskScoreRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreRules(_ store: any RiskScoreRuleStore, query: RiskScoreRuleQuery) -> [RiskScoreRule] {
        return query.apply(store.list())
    }
}
