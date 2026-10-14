import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps legacy order set summaries by code.
    protocol LegacyOrderSetSummaryStore {
        func find(_ code: String) -> LegacyOrderSetSummary?
        func save(_ item: LegacyOrderSetSummary)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyOrderSetSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyOrderSetSummaryStore: LegacyOrderSetSummaryStore {
        var items: [String: LegacyOrderSetSummary]
        var order: [String]

        init(items: [String: LegacyOrderSetSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyOrderSetSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyOrderSetSummary) {
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

        func list() -> [LegacyOrderSetSummary] {
            var out: [LegacyOrderSetSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyOrderSetSummaryStore() -> any LegacyOrderSetSummaryStore {
        return MemoryLegacyOrderSetSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyOrderSetSummaryStore: LegacyOrderSetSummaryStore {
        var inner: MemoryLegacyOrderSetSummaryStore
        var cache: TTLCache<LegacyOrderSetSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyOrderSetSummaryStore, cache: TTLCache<LegacyOrderSetSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyOrderSetSummary? {
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

        func save(_ item: LegacyOrderSetSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyOrderSetSummary] {
            return inner.list()
        }
    }

    static func newCachedLegacyOrderSetSummaryStore(_ inner: MemoryLegacyOrderSetSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyOrderSetSummaryStore {
        return CachedLegacyOrderSetSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy order set summaries. Empty fields match all.
    final class LegacyOrderSetSummaryQuery {
        var country: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyOrderSetSummary) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyOrderSetSummary]) -> [LegacyOrderSetSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyOrderSetSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyOrderSetSummaries(_ store: any LegacyOrderSetSummaryStore, query: LegacyOrderSetSummaryQuery) -> [LegacyOrderSetSummary] {
        return query.apply(store.list())
    }
}
