import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score baselines by code.
    protocol RiskScoreBaselineStore {
        func find(_ code: String) -> RiskScoreBaseline?
        func save(_ item: RiskScoreBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreBaselineStore: RiskScoreBaselineStore {
        var items: [String: RiskScoreBaseline]
        var order: [String]

        init(items: [String: RiskScoreBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreBaseline) {
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

        func list() -> [RiskScoreBaseline] {
            var out: [RiskScoreBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreBaselineStore() -> any RiskScoreBaselineStore {
        return MemoryRiskScoreBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreBaselineStore: RiskScoreBaselineStore {
        var inner: MemoryRiskScoreBaselineStore
        var cache: TTLCache<RiskScoreBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreBaselineStore, cache: TTLCache<RiskScoreBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreBaseline? {
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

        func save(_ item: RiskScoreBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreBaseline] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreBaselineStore(_ inner: MemoryRiskScoreBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreBaselineStore {
        return CachedRiskScoreBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score baselines. Empty fields match all.
    final class RiskScoreBaselineQuery {
        var name: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minWeight: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreBaseline) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreBaseline]) -> [RiskScoreBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreBaselines(_ store: any RiskScoreBaselineStore, query: RiskScoreBaselineQuery) -> [RiskScoreBaseline] {
        return query.apply(store.list())
    }
}
