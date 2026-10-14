import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation summaries by code.
    protocol IsolationSummaryStore {
        func find(_ code: String) -> IsolationSummary?
        func save(_ item: IsolationSummary)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationSummaryStore: IsolationSummaryStore {
        var items: [String: IsolationSummary]
        var order: [String]

        init(items: [String: IsolationSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationSummary) {
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

        func list() -> [IsolationSummary] {
            var out: [IsolationSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationSummaryStore() -> any IsolationSummaryStore {
        return MemoryIsolationSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationSummaryStore: IsolationSummaryStore {
        var inner: MemoryIsolationSummaryStore
        var cache: TTLCache<IsolationSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationSummaryStore, cache: TTLCache<IsolationSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationSummary? {
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

        func save(_ item: IsolationSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationSummary] {
            return inner.list()
        }
    }

    static func newCachedIsolationSummaryStore(_ inner: MemoryIsolationSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationSummaryStore {
        return CachedIsolationSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation summaries. Empty fields match all.
    final class IsolationSummaryQuery {
        var facility: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationSummary) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationSummary]) -> [IsolationSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationSummaries(_ store: any IsolationSummaryStore, query: IsolationSummaryQuery) -> [IsolationSummary] {
        return query.apply(store.list())
    }
}
