import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict claim summaries by code.
    protocol StrictClaimSummaryStore {
        func find(_ code: String) -> StrictClaimSummary?
        func save(_ item: StrictClaimSummary)
        func remove(_ code: String) -> Bool
        func list() -> [StrictClaimSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictClaimSummaryStore: StrictClaimSummaryStore {
        var items: [String: StrictClaimSummary]
        var order: [String]

        init(items: [String: StrictClaimSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictClaimSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictClaimSummary) {
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

        func list() -> [StrictClaimSummary] {
            var out: [StrictClaimSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictClaimSummaryStore() -> any StrictClaimSummaryStore {
        return MemoryStrictClaimSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictClaimSummaryStore: StrictClaimSummaryStore {
        var inner: MemoryStrictClaimSummaryStore
        var cache: TTLCache<StrictClaimSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictClaimSummaryStore, cache: TTLCache<StrictClaimSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictClaimSummary? {
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

        func save(_ item: StrictClaimSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictClaimSummary] {
            return inner.list()
        }
    }

    static func newCachedStrictClaimSummaryStore(_ inner: MemoryStrictClaimSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictClaimSummaryStore {
        return CachedStrictClaimSummaryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict claim summaries. Empty fields match all.
    final class StrictClaimSummaryQuery {
        var source: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictClaimSummary) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictClaimSummary]) -> [StrictClaimSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictClaimSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictClaimSummaries(_ store: any StrictClaimSummaryStore, query: StrictClaimSummaryQuery) -> [StrictClaimSummary] {
        return query.apply(store.list())
    }
}
