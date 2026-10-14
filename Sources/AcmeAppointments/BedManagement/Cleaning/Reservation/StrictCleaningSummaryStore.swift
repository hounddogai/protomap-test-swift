import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps strict cleaning summaries by code.
    protocol StrictCleaningSummaryStore {
        func find(_ code: String) -> StrictCleaningSummary?
        func save(_ item: StrictCleaningSummary)
        func remove(_ code: String) -> Bool
        func list() -> [StrictCleaningSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictCleaningSummaryStore: StrictCleaningSummaryStore {
        var items: [String: StrictCleaningSummary]
        var order: [String]

        init(items: [String: StrictCleaningSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictCleaningSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictCleaningSummary) {
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

        func list() -> [StrictCleaningSummary] {
            var out: [StrictCleaningSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictCleaningSummaryStore() -> any StrictCleaningSummaryStore {
        return MemoryStrictCleaningSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictCleaningSummaryStore: StrictCleaningSummaryStore {
        var inner: MemoryStrictCleaningSummaryStore
        var cache: TTLCache<StrictCleaningSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictCleaningSummaryStore, cache: TTLCache<StrictCleaningSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictCleaningSummary? {
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

        func save(_ item: StrictCleaningSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictCleaningSummary] {
            return inner.list()
        }
    }

    static func newCachedStrictCleaningSummaryStore(_ inner: MemoryStrictCleaningSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictCleaningSummaryStore {
        return CachedStrictCleaningSummaryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict cleaning summaries. Empty fields match all.
    final class StrictCleaningSummaryQuery {
        var channel: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minRate: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictCleaningSummary) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [StrictCleaningSummary]) -> [StrictCleaningSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictCleaningSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictCleaningSummaries(_ store: any StrictCleaningSummaryStore, query: StrictCleaningSummaryQuery) -> [StrictCleaningSummary] {
        return query.apply(store.list())
    }
}
