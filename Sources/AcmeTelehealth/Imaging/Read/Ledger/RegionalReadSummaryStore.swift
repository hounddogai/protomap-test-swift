import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps regional read summaries by code.
    protocol RegionalReadSummaryStore {
        func find(_ code: String) -> RegionalReadSummary?
        func save(_ item: RegionalReadSummary)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalReadSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalReadSummaryStore: RegionalReadSummaryStore {
        var items: [String: RegionalReadSummary]
        var order: [String]

        init(items: [String: RegionalReadSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalReadSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalReadSummary) {
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

        func list() -> [RegionalReadSummary] {
            var out: [RegionalReadSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalReadSummaryStore() -> any RegionalReadSummaryStore {
        return MemoryRegionalReadSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalReadSummaryStore: RegionalReadSummaryStore {
        var inner: MemoryRegionalReadSummaryStore
        var cache: TTLCache<RegionalReadSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalReadSummaryStore, cache: TTLCache<RegionalReadSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalReadSummary? {
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

        func save(_ item: RegionalReadSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalReadSummary] {
            return inner.list()
        }
    }

    static func newCachedRegionalReadSummaryStore(_ inner: MemoryRegionalReadSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalReadSummaryStore {
        return CachedRegionalReadSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional read summaries. Empty fields match all.
    final class RegionalReadSummaryQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalReadSummary) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalReadSummary]) -> [RegionalReadSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalReadSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalReadSummaries(_ store: any RegionalReadSummaryStore, query: RegionalReadSummaryQuery) -> [RegionalReadSummary] {
        return query.apply(store.list())
    }
}
