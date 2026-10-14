import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score estimates by code.
    protocol RiskScoreEstimateStore {
        func find(_ code: String) -> RiskScoreEstimate?
        func save(_ item: RiskScoreEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreEstimateStore: RiskScoreEstimateStore {
        var items: [String: RiskScoreEstimate]
        var order: [String]

        init(items: [String: RiskScoreEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreEstimate) {
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

        func list() -> [RiskScoreEstimate] {
            var out: [RiskScoreEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreEstimateStore() -> any RiskScoreEstimateStore {
        return MemoryRiskScoreEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreEstimateStore: RiskScoreEstimateStore {
        var inner: MemoryRiskScoreEstimateStore
        var cache: TTLCache<RiskScoreEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreEstimateStore, cache: TTLCache<RiskScoreEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreEstimate? {
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

        func save(_ item: RiskScoreEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreEstimate] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreEstimateStore(_ inner: MemoryRiskScoreEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreEstimateStore {
        return CachedRiskScoreEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score estimates. Empty fields match all.
    final class RiskScoreEstimateQuery {
        var facility: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMargin: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreEstimate) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreEstimate]) -> [RiskScoreEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreEstimates(_ store: any RiskScoreEstimateStore, query: RiskScoreEstimateQuery) -> [RiskScoreEstimate] {
        return query.apply(store.list())
    }
}
