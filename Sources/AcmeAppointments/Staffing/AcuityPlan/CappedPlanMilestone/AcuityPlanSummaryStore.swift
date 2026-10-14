import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan summaries by code.
    protocol AcuityPlanSummaryStore {
        func find(_ code: String) -> AcuityPlanSummary?
        func save(_ item: AcuityPlanSummary)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanSummaryStore: AcuityPlanSummaryStore {
        var items: [String: AcuityPlanSummary]
        var order: [String]

        init(items: [String: AcuityPlanSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanSummary) {
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

        func list() -> [AcuityPlanSummary] {
            var out: [AcuityPlanSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanSummaryStore() -> any AcuityPlanSummaryStore {
        return MemoryAcuityPlanSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanSummaryStore: AcuityPlanSummaryStore {
        var inner: MemoryAcuityPlanSummaryStore
        var cache: TTLCache<AcuityPlanSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanSummaryStore, cache: TTLCache<AcuityPlanSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanSummary? {
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

        func save(_ item: AcuityPlanSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanSummary] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanSummaryStore(_ inner: MemoryAcuityPlanSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanSummaryStore {
        return CachedAcuityPlanSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan summaries. Empty fields match all.
    final class AcuityPlanSummaryQuery {
        var category: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanSummary) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanSummary]) -> [AcuityPlanSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanSummaries(_ store: any AcuityPlanSummaryStore, query: AcuityPlanSummaryQuery) -> [AcuityPlanSummary] {
        return query.apply(store.list())
    }
}
