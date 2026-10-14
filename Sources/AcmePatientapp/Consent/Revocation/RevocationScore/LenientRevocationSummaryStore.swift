import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient revocation summaries by code.
    protocol LenientRevocationSummaryStore {
        func find(_ code: String) -> LenientRevocationSummary?
        func save(_ item: LenientRevocationSummary)
        func remove(_ code: String) -> Bool
        func list() -> [LenientRevocationSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientRevocationSummaryStore: LenientRevocationSummaryStore {
        var items: [String: LenientRevocationSummary]
        var order: [String]

        init(items: [String: LenientRevocationSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientRevocationSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientRevocationSummary) {
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

        func list() -> [LenientRevocationSummary] {
            var out: [LenientRevocationSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientRevocationSummaryStore() -> any LenientRevocationSummaryStore {
        return MemoryLenientRevocationSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientRevocationSummaryStore: LenientRevocationSummaryStore {
        var inner: MemoryLenientRevocationSummaryStore
        var cache: TTLCache<LenientRevocationSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientRevocationSummaryStore, cache: TTLCache<LenientRevocationSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientRevocationSummary? {
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

        func save(_ item: LenientRevocationSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientRevocationSummary] {
            return inner.list()
        }
    }

    static func newCachedLenientRevocationSummaryStore(_ inner: MemoryLenientRevocationSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientRevocationSummaryStore {
        return CachedLenientRevocationSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient revocation summaries. Empty fields match all.
    final class LenientRevocationSummaryQuery {
        var unit: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCost: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientRevocationSummary) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientRevocationSummary]) -> [LenientRevocationSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientRevocationSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientRevocationSummaries(_ store: any LenientRevocationSummaryStore, query: LenientRevocationSummaryQuery) -> [LenientRevocationSummary] {
        return query.apply(store.list())
    }
}
