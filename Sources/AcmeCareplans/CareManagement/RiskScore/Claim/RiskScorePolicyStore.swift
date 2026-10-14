import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score policies by code.
    protocol RiskScorePolicyStore {
        func find(_ code: String) -> RiskScorePolicy?
        func save(_ item: RiskScorePolicy)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScorePolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScorePolicyStore: RiskScorePolicyStore {
        var items: [String: RiskScorePolicy]
        var order: [String]

        init(items: [String: RiskScorePolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScorePolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScorePolicy) {
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

        func list() -> [RiskScorePolicy] {
            var out: [RiskScorePolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScorePolicyStore() -> any RiskScorePolicyStore {
        return MemoryRiskScorePolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScorePolicyStore: RiskScorePolicyStore {
        var inner: MemoryRiskScorePolicyStore
        var cache: TTLCache<RiskScorePolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScorePolicyStore, cache: TTLCache<RiskScorePolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScorePolicy? {
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

        func save(_ item: RiskScorePolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScorePolicy] {
            return inner.list()
        }
    }

    static func newCachedRiskScorePolicyStore(_ inner: MemoryRiskScorePolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScorePolicyStore {
        return CachedRiskScorePolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score policies. Empty fields match all.
    final class RiskScorePolicyQuery {
        var category: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minSequence: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScorePolicy) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScorePolicy]) -> [RiskScorePolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScorePolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScorePolicies(_ store: any RiskScorePolicyStore, query: RiskScorePolicyQuery) -> [RiskScorePolicy] {
        return query.apply(store.list())
    }
}
