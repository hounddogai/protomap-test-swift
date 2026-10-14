import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set summaries by code.
    protocol OrderSetSummaryStore {
        func find(_ code: String) -> OrderSetSummary?
        func save(_ item: OrderSetSummary)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetSummaryStore: OrderSetSummaryStore {
        var items: [String: OrderSetSummary]
        var order: [String]

        init(items: [String: OrderSetSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetSummary) {
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

        func list() -> [OrderSetSummary] {
            var out: [OrderSetSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetSummaryStore() -> any OrderSetSummaryStore {
        return MemoryOrderSetSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetSummaryStore: OrderSetSummaryStore {
        var inner: MemoryOrderSetSummaryStore
        var cache: TTLCache<OrderSetSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetSummaryStore, cache: TTLCache<OrderSetSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetSummary? {
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

        func save(_ item: OrderSetSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetSummary] {
            return inner.list()
        }
    }

    static func newCachedOrderSetSummaryStore(_ inner: MemoryOrderSetSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetSummaryStore {
        return CachedOrderSetSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set summaries. Empty fields match all.
    final class OrderSetSummaryQuery {
        var segment: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetSummary) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [OrderSetSummary]) -> [OrderSetSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetSummaries(_ store: any OrderSetSummaryStore, query: OrderSetSummaryQuery) -> [OrderSetSummary] {
        return query.apply(store.list())
    }
}
