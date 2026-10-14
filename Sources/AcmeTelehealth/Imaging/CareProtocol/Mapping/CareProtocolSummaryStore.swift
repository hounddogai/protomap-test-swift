import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol summaries by code.
    protocol CareProtocolSummaryStore {
        func find(_ code: String) -> CareProtocolSummary?
        func save(_ item: CareProtocolSummary)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolSummaryStore: CareProtocolSummaryStore {
        var items: [String: CareProtocolSummary]
        var order: [String]

        init(items: [String: CareProtocolSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolSummary) {
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

        func list() -> [CareProtocolSummary] {
            var out: [CareProtocolSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolSummaryStore() -> any CareProtocolSummaryStore {
        return MemoryCareProtocolSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolSummaryStore: CareProtocolSummaryStore {
        var inner: MemoryCareProtocolSummaryStore
        var cache: TTLCache<CareProtocolSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolSummaryStore, cache: TTLCache<CareProtocolSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolSummary? {
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

        func save(_ item: CareProtocolSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolSummary] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolSummaryStore(_ inner: MemoryCareProtocolSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolSummaryStore {
        return CachedCareProtocolSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol summaries. Empty fields match all.
    final class CareProtocolSummaryQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolSummary) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [CareProtocolSummary]) -> [CareProtocolSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolSummaries(_ store: any CareProtocolSummaryStore, query: CareProtocolSummaryQuery) -> [CareProtocolSummary] {
        return query.apply(store.list())
    }
}
