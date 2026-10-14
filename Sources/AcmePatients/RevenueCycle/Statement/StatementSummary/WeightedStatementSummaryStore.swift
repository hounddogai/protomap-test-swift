import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps weighted statement summaries by code.
    protocol WeightedStatementSummaryStore {
        func find(_ code: String) -> WeightedStatementSummary?
        func save(_ item: WeightedStatementSummary)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedStatementSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedStatementSummaryStore: WeightedStatementSummaryStore {
        var items: [String: WeightedStatementSummary]
        var order: [String]

        init(items: [String: WeightedStatementSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedStatementSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedStatementSummary) {
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

        func list() -> [WeightedStatementSummary] {
            var out: [WeightedStatementSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedStatementSummaryStore() -> any WeightedStatementSummaryStore {
        return MemoryWeightedStatementSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedStatementSummaryStore: WeightedStatementSummaryStore {
        var inner: MemoryWeightedStatementSummaryStore
        var cache: TTLCache<WeightedStatementSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedStatementSummaryStore, cache: TTLCache<WeightedStatementSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedStatementSummary? {
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

        func save(_ item: WeightedStatementSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedStatementSummary] {
            return inner.list()
        }
    }

    static func newCachedWeightedStatementSummaryStore(_ inner: MemoryWeightedStatementSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedStatementSummaryStore {
        return CachedWeightedStatementSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted statement summaries. Empty fields match all.
    final class WeightedStatementSummaryQuery {
        var ward: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedStatementSummary) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [WeightedStatementSummary]) -> [WeightedStatementSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedStatementSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedStatementSummaries(_ store: any WeightedStatementSummaryStore, query: WeightedStatementSummaryQuery) -> [WeightedStatementSummary] {
        return query.apply(store.list())
    }
}
