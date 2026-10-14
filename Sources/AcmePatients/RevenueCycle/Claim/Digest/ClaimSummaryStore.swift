import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim summaries by code.
    protocol ClaimSummaryStore {
        func find(_ code: String) -> ClaimSummary?
        func save(_ item: ClaimSummary)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimSummaryStore: ClaimSummaryStore {
        var items: [String: ClaimSummary]
        var order: [String]

        init(items: [String: ClaimSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimSummary) {
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

        func list() -> [ClaimSummary] {
            var out: [ClaimSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimSummaryStore() -> any ClaimSummaryStore {
        return MemoryClaimSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimSummaryStore: ClaimSummaryStore {
        var inner: MemoryClaimSummaryStore
        var cache: TTLCache<ClaimSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimSummaryStore, cache: TTLCache<ClaimSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimSummary? {
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

        func save(_ item: ClaimSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimSummary] {
            return inner.list()
        }
    }

    static func newCachedClaimSummaryStore(_ inner: MemoryClaimSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimSummaryStore {
        return CachedClaimSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim summaries. Empty fields match all.
    final class ClaimSummaryQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimSummary) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ClaimSummary]) -> [ClaimSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimSummaries(_ store: any ClaimSummaryStore, query: ClaimSummaryQuery) -> [ClaimSummary] {
        return query.apply(store.list())
    }
}
