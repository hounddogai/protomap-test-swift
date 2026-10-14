import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result summaries by code.
    protocol ResultSummaryStore {
        func find(_ code: String) -> ResultSummary?
        func save(_ item: ResultSummary)
        func remove(_ code: String) -> Bool
        func list() -> [ResultSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultSummaryStore: ResultSummaryStore {
        var items: [String: ResultSummary]
        var order: [String]

        init(items: [String: ResultSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultSummary) {
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

        func list() -> [ResultSummary] {
            var out: [ResultSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultSummaryStore() -> any ResultSummaryStore {
        return MemoryResultSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultSummaryStore: ResultSummaryStore {
        var inner: MemoryResultSummaryStore
        var cache: TTLCache<ResultSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultSummaryStore, cache: TTLCache<ResultSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultSummary? {
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

        func save(_ item: ResultSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultSummary] {
            return inner.list()
        }
    }

    static func newCachedResultSummaryStore(_ inner: MemoryResultSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultSummaryStore {
        return CachedResultSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result summaries. Empty fields match all.
    final class ResultSummaryQuery {
        var source: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRate: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultSummary) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [ResultSummary]) -> [ResultSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultSummaries(_ store: any ResultSummaryStore, query: ResultSummaryQuery) -> [ResultSummary] {
        return query.apply(store.list())
    }
}
