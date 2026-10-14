import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending reference range summaries by code.
    protocol PendingReferenceRangeSummaryStore {
        func find(_ code: String) -> PendingReferenceRangeSummary?
        func save(_ item: PendingReferenceRangeSummary)
        func remove(_ code: String) -> Bool
        func list() -> [PendingReferenceRangeSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingReferenceRangeSummaryStore: PendingReferenceRangeSummaryStore {
        var items: [String: PendingReferenceRangeSummary]
        var order: [String]

        init(items: [String: PendingReferenceRangeSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingReferenceRangeSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingReferenceRangeSummary) {
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

        func list() -> [PendingReferenceRangeSummary] {
            var out: [PendingReferenceRangeSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingReferenceRangeSummaryStore() -> any PendingReferenceRangeSummaryStore {
        return MemoryPendingReferenceRangeSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingReferenceRangeSummaryStore: PendingReferenceRangeSummaryStore {
        var inner: MemoryPendingReferenceRangeSummaryStore
        var cache: TTLCache<PendingReferenceRangeSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingReferenceRangeSummaryStore, cache: TTLCache<PendingReferenceRangeSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingReferenceRangeSummary? {
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

        func save(_ item: PendingReferenceRangeSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingReferenceRangeSummary] {
            return inner.list()
        }
    }

    static func newCachedPendingReferenceRangeSummaryStore(_ inner: MemoryPendingReferenceRangeSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingReferenceRangeSummaryStore {
        return CachedPendingReferenceRangeSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending reference range summaries. Empty fields match all.
    final class PendingReferenceRangeSummaryQuery {
        var unit: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingReferenceRangeSummary) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [PendingReferenceRangeSummary]) -> [PendingReferenceRangeSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingReferenceRangeSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingReferenceRangeSummaries(_ store: any PendingReferenceRangeSummaryStore, query: PendingReferenceRangeSummaryQuery) -> [PendingReferenceRangeSummary] {
        return query.apply(store.list())
    }
}
