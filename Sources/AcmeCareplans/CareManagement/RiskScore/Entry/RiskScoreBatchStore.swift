import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score batches by code.
    protocol RiskScoreBatchStore {
        func find(_ code: String) -> RiskScoreBatch?
        func save(_ item: RiskScoreBatch)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreBatchStore: RiskScoreBatchStore {
        var items: [String: RiskScoreBatch]
        var order: [String]

        init(items: [String: RiskScoreBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreBatch) {
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

        func list() -> [RiskScoreBatch] {
            var out: [RiskScoreBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreBatchStore() -> any RiskScoreBatchStore {
        return MemoryRiskScoreBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreBatchStore: RiskScoreBatchStore {
        var inner: MemoryRiskScoreBatchStore
        var cache: TTLCache<RiskScoreBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreBatchStore, cache: TTLCache<RiskScoreBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreBatch? {
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

        func save(_ item: RiskScoreBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreBatch] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreBatchStore(_ inner: MemoryRiskScoreBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreBatchStore {
        return CachedRiskScoreBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score batches. Empty fields match all.
    final class RiskScoreBatchQuery {
        var country: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreBatch) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreBatch]) -> [RiskScoreBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreBatches(_ store: any RiskScoreBatchStore, query: RiskScoreBatchQuery) -> [RiskScoreBatch] {
        return query.apply(store.list())
    }
}
