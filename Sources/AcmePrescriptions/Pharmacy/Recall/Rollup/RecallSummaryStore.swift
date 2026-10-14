import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall summaries by code.
    protocol RecallSummaryStore {
        func find(_ code: String) -> RecallSummary?
        func save(_ item: RecallSummary)
        func remove(_ code: String) -> Bool
        func list() -> [RecallSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallSummaryStore: RecallSummaryStore {
        var items: [String: RecallSummary]
        var order: [String]

        init(items: [String: RecallSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallSummary) {
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

        func list() -> [RecallSummary] {
            var out: [RecallSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallSummaryStore() -> any RecallSummaryStore {
        return MemoryRecallSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallSummaryStore: RecallSummaryStore {
        var inner: MemoryRecallSummaryStore
        var cache: TTLCache<RecallSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallSummaryStore, cache: TTLCache<RecallSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallSummary? {
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

        func save(_ item: RecallSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallSummary] {
            return inner.list()
        }
    }

    static func newCachedRecallSummaryStore(_ inner: MemoryRecallSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallSummaryStore {
        return CachedRecallSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall summaries. Empty fields match all.
    final class RecallSummaryQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallSummary) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [RecallSummary]) -> [RecallSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallSummaries(_ store: any RecallSummaryStore, query: RecallSummaryQuery) -> [RecallSummary] {
        return query.apply(store.list())
    }
}
