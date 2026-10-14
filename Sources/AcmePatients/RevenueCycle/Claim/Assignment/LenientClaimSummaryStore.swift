import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient claim summaries by code.
    protocol LenientClaimSummaryStore {
        func find(_ code: String) -> LenientClaimSummary?
        func save(_ item: LenientClaimSummary)
        func remove(_ code: String) -> Bool
        func list() -> [LenientClaimSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientClaimSummaryStore: LenientClaimSummaryStore {
        var items: [String: LenientClaimSummary]
        var order: [String]

        init(items: [String: LenientClaimSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientClaimSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientClaimSummary) {
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

        func list() -> [LenientClaimSummary] {
            var out: [LenientClaimSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientClaimSummaryStore() -> any LenientClaimSummaryStore {
        return MemoryLenientClaimSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientClaimSummaryStore: LenientClaimSummaryStore {
        var inner: MemoryLenientClaimSummaryStore
        var cache: TTLCache<LenientClaimSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientClaimSummaryStore, cache: TTLCache<LenientClaimSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientClaimSummary? {
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

        func save(_ item: LenientClaimSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientClaimSummary] {
            return inner.list()
        }
    }

    static func newCachedLenientClaimSummaryStore(_ inner: MemoryLenientClaimSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientClaimSummaryStore {
        return CachedLenientClaimSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient claim summaries. Empty fields match all.
    final class LenientClaimSummaryQuery {
        var source: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientClaimSummary) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientClaimSummary]) -> [LenientClaimSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientClaimSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientClaimSummaries(_ store: any LenientClaimSummaryStore, query: LenientClaimSummaryQuery) -> [LenientClaimSummary] {
        return query.apply(store.list())
    }
}
