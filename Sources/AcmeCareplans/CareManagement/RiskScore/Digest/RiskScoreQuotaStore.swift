import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score quotas by code.
    protocol RiskScoreQuotaStore {
        func find(_ code: String) -> RiskScoreQuota?
        func save(_ item: RiskScoreQuota)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreQuotaStore: RiskScoreQuotaStore {
        var items: [String: RiskScoreQuota]
        var order: [String]

        init(items: [String: RiskScoreQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreQuota) {
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

        func list() -> [RiskScoreQuota] {
            var out: [RiskScoreQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreQuotaStore() -> any RiskScoreQuotaStore {
        return MemoryRiskScoreQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreQuotaStore: RiskScoreQuotaStore {
        var inner: MemoryRiskScoreQuotaStore
        var cache: TTLCache<RiskScoreQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreQuotaStore, cache: TTLCache<RiskScoreQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreQuota? {
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

        func save(_ item: RiskScoreQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreQuota] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreQuotaStore(_ inner: MemoryRiskScoreQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreQuotaStore {
        return CachedRiskScoreQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score quotas. Empty fields match all.
    final class RiskScoreQuotaQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreQuota) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [RiskScoreQuota]) -> [RiskScoreQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreQuotas(_ store: any RiskScoreQuotaStore, query: RiskScoreQuotaQuery) -> [RiskScoreQuota] {
        return query.apply(store.list())
    }
}
