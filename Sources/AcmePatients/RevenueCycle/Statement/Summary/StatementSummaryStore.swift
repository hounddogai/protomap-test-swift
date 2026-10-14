import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement summaries by code.
    protocol StatementSummaryStore {
        func find(_ code: String) -> StatementSummary?
        func save(_ item: StatementSummary)
        func remove(_ code: String) -> Bool
        func list() -> [StatementSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementSummaryStore: StatementSummaryStore {
        var items: [String: StatementSummary]
        var order: [String]

        init(items: [String: StatementSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementSummary) {
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

        func list() -> [StatementSummary] {
            var out: [StatementSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementSummaryStore() -> any StatementSummaryStore {
        return MemoryStatementSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementSummaryStore: StatementSummaryStore {
        var inner: MemoryStatementSummaryStore
        var cache: TTLCache<StatementSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementSummaryStore, cache: TTLCache<StatementSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementSummary? {
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

        func save(_ item: StatementSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementSummary] {
            return inner.list()
        }
    }

    static func newCachedStatementSummaryStore(_ inner: MemoryStatementSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementSummaryStore {
        return CachedStatementSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement summaries. Empty fields match all.
    final class StatementSummaryQuery {
        var ward: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minSequence: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementSummary) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementSummary]) -> [StatementSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementSummaries(_ store: any StatementSummaryStore, query: StatementSummaryQuery) -> [StatementSummary] {
        return query.apply(store.list())
    }
}
