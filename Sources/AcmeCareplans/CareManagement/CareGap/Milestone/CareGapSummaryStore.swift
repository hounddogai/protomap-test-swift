import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap summaries by code.
    protocol CareGapSummaryStore {
        func find(_ code: String) -> CareGapSummary?
        func save(_ item: CareGapSummary)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapSummaryStore: CareGapSummaryStore {
        var items: [String: CareGapSummary]
        var order: [String]

        init(items: [String: CareGapSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapSummary) {
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

        func list() -> [CareGapSummary] {
            var out: [CareGapSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapSummaryStore() -> any CareGapSummaryStore {
        return MemoryCareGapSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapSummaryStore: CareGapSummaryStore {
        var inner: MemoryCareGapSummaryStore
        var cache: TTLCache<CareGapSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapSummaryStore, cache: TTLCache<CareGapSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapSummary? {
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

        func save(_ item: CareGapSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapSummary] {
            return inner.list()
        }
    }

    static func newCachedCareGapSummaryStore(_ inner: MemoryCareGapSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapSummaryStore {
        return CachedCareGapSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap summaries. Empty fields match all.
    final class CareGapSummaryQuery {
        var title: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapSummary]) -> [CareGapSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapSummaries(_ store: any CareGapSummaryStore, query: CareGapSummaryQuery) -> [CareGapSummary] {
        return query.apply(store.list())
    }
}
