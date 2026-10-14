import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task summaries by code.
    protocol TaskSummaryStore {
        func find(_ code: String) -> TaskSummary?
        func save(_ item: TaskSummary)
        func remove(_ code: String) -> Bool
        func list() -> [TaskSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskSummaryStore: TaskSummaryStore {
        var items: [String: TaskSummary]
        var order: [String]

        init(items: [String: TaskSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskSummary) {
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

        func list() -> [TaskSummary] {
            var out: [TaskSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskSummaryStore() -> any TaskSummaryStore {
        return MemoryTaskSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskSummaryStore: TaskSummaryStore {
        var inner: MemoryTaskSummaryStore
        var cache: TTLCache<TaskSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskSummaryStore, cache: TTLCache<TaskSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskSummary? {
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

        func save(_ item: TaskSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskSummary] {
            return inner.list()
        }
    }

    static func newCachedTaskSummaryStore(_ inner: MemoryTaskSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskSummaryStore {
        return CachedTaskSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task summaries. Empty fields match all.
    final class TaskSummaryQuery {
        var name: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskSummary) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskSummary]) -> [TaskSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskSummaries(_ store: any TaskSummaryStore, query: TaskSummaryQuery) -> [TaskSummary] {
        return query.apply(store.list())
    }
}
