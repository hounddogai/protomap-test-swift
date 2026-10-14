import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional float pool summaries by code.
    protocol RegionalFloatPoolSummaryStore {
        func find(_ code: String) -> RegionalFloatPoolSummary?
        func save(_ item: RegionalFloatPoolSummary)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalFloatPoolSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalFloatPoolSummaryStore: RegionalFloatPoolSummaryStore {
        var items: [String: RegionalFloatPoolSummary]
        var order: [String]

        init(items: [String: RegionalFloatPoolSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalFloatPoolSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalFloatPoolSummary) {
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

        func list() -> [RegionalFloatPoolSummary] {
            var out: [RegionalFloatPoolSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalFloatPoolSummaryStore() -> any RegionalFloatPoolSummaryStore {
        return MemoryRegionalFloatPoolSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalFloatPoolSummaryStore: RegionalFloatPoolSummaryStore {
        var inner: MemoryRegionalFloatPoolSummaryStore
        var cache: TTLCache<RegionalFloatPoolSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalFloatPoolSummaryStore, cache: TTLCache<RegionalFloatPoolSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalFloatPoolSummary? {
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

        func save(_ item: RegionalFloatPoolSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalFloatPoolSummary] {
            return inner.list()
        }
    }

    static func newCachedRegionalFloatPoolSummaryStore(_ inner: MemoryRegionalFloatPoolSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalFloatPoolSummaryStore {
        return CachedRegionalFloatPoolSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional float pool summaries. Empty fields match all.
    final class RegionalFloatPoolSummaryQuery {
        var ward: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minScore: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalFloatPoolSummary) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [RegionalFloatPoolSummary]) -> [RegionalFloatPoolSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalFloatPoolSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalFloatPoolSummaries(_ store: any RegionalFloatPoolSummaryStore, query: RegionalFloatPoolSummaryQuery) -> [RegionalFloatPoolSummary] {
        return query.apply(store.list())
    }
}
