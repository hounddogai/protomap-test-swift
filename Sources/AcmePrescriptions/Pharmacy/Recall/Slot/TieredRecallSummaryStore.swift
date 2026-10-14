import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps tiered recall summaries by code.
    protocol TieredRecallSummaryStore {
        func find(_ code: String) -> TieredRecallSummary?
        func save(_ item: TieredRecallSummary)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRecallSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRecallSummaryStore: TieredRecallSummaryStore {
        var items: [String: TieredRecallSummary]
        var order: [String]

        init(items: [String: TieredRecallSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRecallSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRecallSummary) {
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

        func list() -> [TieredRecallSummary] {
            var out: [TieredRecallSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRecallSummaryStore() -> any TieredRecallSummaryStore {
        return MemoryTieredRecallSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRecallSummaryStore: TieredRecallSummaryStore {
        var inner: MemoryTieredRecallSummaryStore
        var cache: TTLCache<TieredRecallSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRecallSummaryStore, cache: TTLCache<TieredRecallSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRecallSummary? {
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

        func save(_ item: TieredRecallSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRecallSummary] {
            return inner.list()
        }
    }

    static func newCachedTieredRecallSummaryStore(_ inner: MemoryTieredRecallSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRecallSummaryStore {
        return CachedTieredRecallSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered recall summaries. Empty fields match all.
    final class TieredRecallSummaryQuery {
        var country: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minAmount: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRecallSummary) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredRecallSummary]) -> [TieredRecallSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRecallSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRecallSummaries(_ store: any TieredRecallSummaryStore, query: TieredRecallSummaryQuery) -> [TieredRecallSummary] {
        return query.apply(store.list())
    }
}
