import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual care gap summaries by code.
    protocol ManualCareGapSummaryStore {
        func find(_ code: String) -> ManualCareGapSummary?
        func save(_ item: ManualCareGapSummary)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCareGapSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCareGapSummaryStore: ManualCareGapSummaryStore {
        var items: [String: ManualCareGapSummary]
        var order: [String]

        init(items: [String: ManualCareGapSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCareGapSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCareGapSummary) {
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

        func list() -> [ManualCareGapSummary] {
            var out: [ManualCareGapSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCareGapSummaryStore() -> any ManualCareGapSummaryStore {
        return MemoryManualCareGapSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCareGapSummaryStore: ManualCareGapSummaryStore {
        var inner: MemoryManualCareGapSummaryStore
        var cache: TTLCache<ManualCareGapSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCareGapSummaryStore, cache: TTLCache<ManualCareGapSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCareGapSummary? {
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

        func save(_ item: ManualCareGapSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCareGapSummary] {
            return inner.list()
        }
    }

    static func newCachedManualCareGapSummaryStore(_ inner: MemoryManualCareGapSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCareGapSummaryStore {
        return CachedManualCareGapSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual care gap summaries. Empty fields match all.
    final class ManualCareGapSummaryQuery {
        var country: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCareGapSummary) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualCareGapSummary]) -> [ManualCareGapSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCareGapSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCareGapSummaries(_ store: any ManualCareGapSummaryStore, query: ManualCareGapSummaryQuery) -> [ManualCareGapSummary] {
        return query.apply(store.list())
    }
}
