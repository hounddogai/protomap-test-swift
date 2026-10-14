import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered study summaries by code.
    protocol TieredStudySummaryStore {
        func find(_ code: String) -> TieredStudySummary?
        func save(_ item: TieredStudySummary)
        func remove(_ code: String) -> Bool
        func list() -> [TieredStudySummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredStudySummaryStore: TieredStudySummaryStore {
        var items: [String: TieredStudySummary]
        var order: [String]

        init(items: [String: TieredStudySummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredStudySummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredStudySummary) {
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

        func list() -> [TieredStudySummary] {
            var out: [TieredStudySummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredStudySummaryStore() -> any TieredStudySummaryStore {
        return MemoryTieredStudySummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredStudySummaryStore: TieredStudySummaryStore {
        var inner: MemoryTieredStudySummaryStore
        var cache: TTLCache<TieredStudySummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredStudySummaryStore, cache: TTLCache<TieredStudySummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredStudySummary? {
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

        func save(_ item: TieredStudySummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredStudySummary] {
            return inner.list()
        }
    }

    static func newCachedTieredStudySummaryStore(_ inner: MemoryTieredStudySummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredStudySummaryStore {
        return CachedTieredStudySummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered study summaries. Empty fields match all.
    final class TieredStudySummaryQuery {
        var region: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredStudySummary) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredStudySummary]) -> [TieredStudySummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredStudySummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredStudySummaries(_ store: any TieredStudySummaryStore, query: TieredStudySummaryQuery) -> [TieredStudySummary] {
        return query.apply(store.list())
    }
}
