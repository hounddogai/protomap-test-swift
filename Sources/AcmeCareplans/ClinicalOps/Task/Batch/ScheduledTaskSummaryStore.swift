import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps scheduled task summaries by code.
    protocol ScheduledTaskSummaryStore {
        func find(_ code: String) -> ScheduledTaskSummary?
        func save(_ item: ScheduledTaskSummary)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledTaskSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledTaskSummaryStore: ScheduledTaskSummaryStore {
        var items: [String: ScheduledTaskSummary]
        var order: [String]

        init(items: [String: ScheduledTaskSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledTaskSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledTaskSummary) {
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

        func list() -> [ScheduledTaskSummary] {
            var out: [ScheduledTaskSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledTaskSummaryStore() -> any ScheduledTaskSummaryStore {
        return MemoryScheduledTaskSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledTaskSummaryStore: ScheduledTaskSummaryStore {
        var inner: MemoryScheduledTaskSummaryStore
        var cache: TTLCache<ScheduledTaskSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledTaskSummaryStore, cache: TTLCache<ScheduledTaskSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledTaskSummary? {
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

        func save(_ item: ScheduledTaskSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledTaskSummary] {
            return inner.list()
        }
    }

    static func newCachedScheduledTaskSummaryStore(_ inner: MemoryScheduledTaskSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledTaskSummaryStore {
        return CachedScheduledTaskSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled task summaries. Empty fields match all.
    final class ScheduledTaskSummaryQuery {
        var facility: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledTaskSummary) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledTaskSummary]) -> [ScheduledTaskSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledTaskSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledTaskSummaries(_ store: any ScheduledTaskSummaryStore, query: ScheduledTaskSummaryQuery) -> [ScheduledTaskSummary] {
        return query.apply(store.list())
    }
}
