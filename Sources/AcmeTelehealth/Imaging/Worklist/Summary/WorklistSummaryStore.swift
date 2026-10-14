import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist summaries by code.
    protocol WorklistSummaryStore {
        func find(_ code: String) -> WorklistSummary?
        func save(_ item: WorklistSummary)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistSummaryStore: WorklistSummaryStore {
        var items: [String: WorklistSummary]
        var order: [String]

        init(items: [String: WorklistSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistSummary) {
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

        func list() -> [WorklistSummary] {
            var out: [WorklistSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistSummaryStore() -> any WorklistSummaryStore {
        return MemoryWorklistSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistSummaryStore: WorklistSummaryStore {
        var inner: MemoryWorklistSummaryStore
        var cache: TTLCache<WorklistSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistSummaryStore, cache: TTLCache<WorklistSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistSummary? {
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

        func save(_ item: WorklistSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistSummary] {
            return inner.list()
        }
    }

    static func newCachedWorklistSummaryStore(_ inner: MemoryWorklistSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistSummaryStore {
        return CachedWorklistSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist summaries. Empty fields match all.
    final class WorklistSummaryQuery {
        var title: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minSequence: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [WorklistSummary]) -> [WorklistSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistSummaries(_ store: any WorklistSummaryStore, query: WorklistSummaryQuery) -> [WorklistSummary] {
        return query.apply(store.list())
    }
}
