import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps scheduled care protocol summaries by code.
    protocol ScheduledCareProtocolSummaryStore {
        func find(_ code: String) -> ScheduledCareProtocolSummary?
        func save(_ item: ScheduledCareProtocolSummary)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCareProtocolSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCareProtocolSummaryStore: ScheduledCareProtocolSummaryStore {
        var items: [String: ScheduledCareProtocolSummary]
        var order: [String]

        init(items: [String: ScheduledCareProtocolSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCareProtocolSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCareProtocolSummary) {
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

        func list() -> [ScheduledCareProtocolSummary] {
            var out: [ScheduledCareProtocolSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCareProtocolSummaryStore() -> any ScheduledCareProtocolSummaryStore {
        return MemoryScheduledCareProtocolSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCareProtocolSummaryStore: ScheduledCareProtocolSummaryStore {
        var inner: MemoryScheduledCareProtocolSummaryStore
        var cache: TTLCache<ScheduledCareProtocolSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCareProtocolSummaryStore, cache: TTLCache<ScheduledCareProtocolSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCareProtocolSummary? {
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

        func save(_ item: ScheduledCareProtocolSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCareProtocolSummary] {
            return inner.list()
        }
    }

    static func newCachedScheduledCareProtocolSummaryStore(_ inner: MemoryScheduledCareProtocolSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCareProtocolSummaryStore {
        return CachedScheduledCareProtocolSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled care protocol summaries. Empty fields match all.
    final class ScheduledCareProtocolSummaryQuery {
        var facility: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minRate: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCareProtocolSummary) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [ScheduledCareProtocolSummary]) -> [ScheduledCareProtocolSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCareProtocolSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCareProtocolSummaries(_ store: any ScheduledCareProtocolSummaryStore, query: ScheduledCareProtocolSummaryQuery) -> [ScheduledCareProtocolSummary] {
        return query.apply(store.list())
    }
}
