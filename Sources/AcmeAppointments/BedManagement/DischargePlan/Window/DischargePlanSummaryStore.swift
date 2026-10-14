import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan summaries by code.
    protocol DischargePlanSummaryStore {
        func find(_ code: String) -> DischargePlanSummary?
        func save(_ item: DischargePlanSummary)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanSummaryStore: DischargePlanSummaryStore {
        var items: [String: DischargePlanSummary]
        var order: [String]

        init(items: [String: DischargePlanSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanSummary) {
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

        func list() -> [DischargePlanSummary] {
            var out: [DischargePlanSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanSummaryStore() -> any DischargePlanSummaryStore {
        return MemoryDischargePlanSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanSummaryStore: DischargePlanSummaryStore {
        var inner: MemoryDischargePlanSummaryStore
        var cache: TTLCache<DischargePlanSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanSummaryStore, cache: TTLCache<DischargePlanSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanSummary? {
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

        func save(_ item: DischargePlanSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanSummary] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanSummaryStore(_ inner: MemoryDischargePlanSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanSummaryStore {
        return CachedDischargePlanSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan summaries. Empty fields match all.
    final class DischargePlanSummaryQuery {
        var country: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanSummary) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [DischargePlanSummary]) -> [DischargePlanSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanSummaries(_ store: any DischargePlanSummaryStore, query: DischargePlanSummaryQuery) -> [DischargePlanSummary] {
        return query.apply(store.list())
    }
}
