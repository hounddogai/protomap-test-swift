import AcmePlatform
import Foundation

extension Consent {
    /// Keeps weighted proxy summaries by code.
    protocol WeightedProxySummaryStore {
        func find(_ code: String) -> WeightedProxySummary?
        func save(_ item: WeightedProxySummary)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedProxySummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedProxySummaryStore: WeightedProxySummaryStore {
        var items: [String: WeightedProxySummary]
        var order: [String]

        init(items: [String: WeightedProxySummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedProxySummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedProxySummary) {
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

        func list() -> [WeightedProxySummary] {
            var out: [WeightedProxySummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedProxySummaryStore() -> any WeightedProxySummaryStore {
        return MemoryWeightedProxySummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedProxySummaryStore: WeightedProxySummaryStore {
        var inner: MemoryWeightedProxySummaryStore
        var cache: TTLCache<WeightedProxySummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedProxySummaryStore, cache: TTLCache<WeightedProxySummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedProxySummary? {
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

        func save(_ item: WeightedProxySummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedProxySummary] {
            return inner.list()
        }
    }

    static func newCachedWeightedProxySummaryStore(_ inner: MemoryWeightedProxySummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedProxySummaryStore {
        return CachedWeightedProxySummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted proxy summaries. Empty fields match all.
    final class WeightedProxySummaryQuery {
        var facility: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedProxySummary) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [WeightedProxySummary]) -> [WeightedProxySummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedProxySummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedProxySummaries(_ store: any WeightedProxySummaryStore, query: WeightedProxySummaryQuery) -> [WeightedProxySummary] {
        return query.apply(store.list())
    }
}
