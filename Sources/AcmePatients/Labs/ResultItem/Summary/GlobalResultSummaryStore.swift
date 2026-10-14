import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global result summaries by code.
    protocol GlobalResultSummaryStore {
        func find(_ code: String) -> GlobalResultSummary?
        func save(_ item: GlobalResultSummary)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalResultSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalResultSummaryStore: GlobalResultSummaryStore {
        var items: [String: GlobalResultSummary]
        var order: [String]

        init(items: [String: GlobalResultSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalResultSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalResultSummary) {
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

        func list() -> [GlobalResultSummary] {
            var out: [GlobalResultSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalResultSummaryStore() -> any GlobalResultSummaryStore {
        return MemoryGlobalResultSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalResultSummaryStore: GlobalResultSummaryStore {
        var inner: MemoryGlobalResultSummaryStore
        var cache: TTLCache<GlobalResultSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalResultSummaryStore, cache: TTLCache<GlobalResultSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalResultSummary? {
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

        func save(_ item: GlobalResultSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalResultSummary] {
            return inner.list()
        }
    }

    static func newCachedGlobalResultSummaryStore(_ inner: MemoryGlobalResultSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalResultSummaryStore {
        return CachedGlobalResultSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global result summaries. Empty fields match all.
    final class GlobalResultSummaryQuery {
        var channel: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minRate: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalResultSummary) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalResultSummary]) -> [GlobalResultSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalResultSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalResultSummaries(_ store: any GlobalResultSummaryStore, query: GlobalResultSummaryQuery) -> [GlobalResultSummary] {
        return query.apply(store.list())
    }
}
