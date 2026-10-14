import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending priority summaries by code.
    protocol PendingPrioritySummaryStore {
        func find(_ code: String) -> PendingPrioritySummary?
        func save(_ item: PendingPrioritySummary)
        func remove(_ code: String) -> Bool
        func list() -> [PendingPrioritySummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingPrioritySummaryStore: PendingPrioritySummaryStore {
        var items: [String: PendingPrioritySummary]
        var order: [String]

        init(items: [String: PendingPrioritySummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingPrioritySummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingPrioritySummary) {
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

        func list() -> [PendingPrioritySummary] {
            var out: [PendingPrioritySummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingPrioritySummaryStore() -> any PendingPrioritySummaryStore {
        return MemoryPendingPrioritySummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingPrioritySummaryStore: PendingPrioritySummaryStore {
        var inner: MemoryPendingPrioritySummaryStore
        var cache: TTLCache<PendingPrioritySummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingPrioritySummaryStore, cache: TTLCache<PendingPrioritySummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingPrioritySummary? {
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

        func save(_ item: PendingPrioritySummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingPrioritySummary] {
            return inner.list()
        }
    }

    static func newCachedPendingPrioritySummaryStore(_ inner: MemoryPendingPrioritySummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingPrioritySummaryStore {
        return CachedPendingPrioritySummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending priority summaries. Empty fields match all.
    final class PendingPrioritySummaryQuery {
        var name: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingPrioritySummary) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [PendingPrioritySummary]) -> [PendingPrioritySummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingPrioritySummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingPrioritySummaries(_ store: any PendingPrioritySummaryStore, query: PendingPrioritySummaryQuery) -> [PendingPrioritySummary] {
        return query.apply(store.list())
    }
}
