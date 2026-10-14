import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps global recall summaries by code.
    protocol GlobalRecallSummaryStore {
        func find(_ code: String) -> GlobalRecallSummary?
        func save(_ item: GlobalRecallSummary)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalRecallSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalRecallSummaryStore: GlobalRecallSummaryStore {
        var items: [String: GlobalRecallSummary]
        var order: [String]

        init(items: [String: GlobalRecallSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalRecallSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalRecallSummary) {
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

        func list() -> [GlobalRecallSummary] {
            var out: [GlobalRecallSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalRecallSummaryStore() -> any GlobalRecallSummaryStore {
        return MemoryGlobalRecallSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalRecallSummaryStore: GlobalRecallSummaryStore {
        var inner: MemoryGlobalRecallSummaryStore
        var cache: TTLCache<GlobalRecallSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalRecallSummaryStore, cache: TTLCache<GlobalRecallSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalRecallSummary? {
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

        func save(_ item: GlobalRecallSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalRecallSummary] {
            return inner.list()
        }
    }

    static func newCachedGlobalRecallSummaryStore(_ inner: MemoryGlobalRecallSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalRecallSummaryStore {
        return CachedGlobalRecallSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global recall summaries. Empty fields match all.
    final class GlobalRecallSummaryQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalRecallSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [GlobalRecallSummary]) -> [GlobalRecallSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalRecallSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalRecallSummaries(_ store: any GlobalRecallSummaryStore, query: GlobalRecallSummaryQuery) -> [GlobalRecallSummary] {
        return query.apply(store.list())
    }
}
