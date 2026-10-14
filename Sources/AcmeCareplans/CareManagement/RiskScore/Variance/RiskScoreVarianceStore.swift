import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score variances by code.
    protocol RiskScoreVarianceStore {
        func find(_ code: String) -> RiskScoreVariance?
        func save(_ item: RiskScoreVariance)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreVarianceStore: RiskScoreVarianceStore {
        var items: [String: RiskScoreVariance]
        var order: [String]

        init(items: [String: RiskScoreVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreVariance) {
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

        func list() -> [RiskScoreVariance] {
            var out: [RiskScoreVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreVarianceStore() -> any RiskScoreVarianceStore {
        return MemoryRiskScoreVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreVarianceStore: RiskScoreVarianceStore {
        var inner: MemoryRiskScoreVarianceStore
        var cache: TTLCache<RiskScoreVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreVarianceStore, cache: TTLCache<RiskScoreVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreVariance? {
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

        func save(_ item: RiskScoreVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreVariance] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreVarianceStore(_ inner: MemoryRiskScoreVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreVarianceStore {
        return CachedRiskScoreVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score variances. Empty fields match all.
    final class RiskScoreVarianceQuery {
        var segment: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreVariance) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreVariance]) -> [RiskScoreVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreVariances(_ store: any RiskScoreVarianceStore, query: RiskScoreVarianceQuery) -> [RiskScoreVariance] {
        return query.apply(store.list())
    }
}
