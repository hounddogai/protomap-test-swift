import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive claim summaries by code.
    protocol AdaptiveClaimSummaryStore {
        func find(_ code: String) -> AdaptiveClaimSummary?
        func save(_ item: AdaptiveClaimSummary)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveClaimSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveClaimSummaryStore: AdaptiveClaimSummaryStore {
        var items: [String: AdaptiveClaimSummary]
        var order: [String]

        init(items: [String: AdaptiveClaimSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveClaimSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveClaimSummary) {
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

        func list() -> [AdaptiveClaimSummary] {
            var out: [AdaptiveClaimSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveClaimSummaryStore() -> any AdaptiveClaimSummaryStore {
        return MemoryAdaptiveClaimSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveClaimSummaryStore: AdaptiveClaimSummaryStore {
        var inner: MemoryAdaptiveClaimSummaryStore
        var cache: TTLCache<AdaptiveClaimSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveClaimSummaryStore, cache: TTLCache<AdaptiveClaimSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveClaimSummary? {
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

        func save(_ item: AdaptiveClaimSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveClaimSummary] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveClaimSummaryStore(_ inner: MemoryAdaptiveClaimSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveClaimSummaryStore {
        return CachedAdaptiveClaimSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive claim summaries. Empty fields match all.
    final class AdaptiveClaimSummaryQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveClaimSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [AdaptiveClaimSummary]) -> [AdaptiveClaimSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveClaimSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveClaimSummaries(_ store: any AdaptiveClaimSummaryStore, query: AdaptiveClaimSummaryQuery) -> [AdaptiveClaimSummary] {
        return query.apply(store.list())
    }
}
