import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps default cleaning summaries by code.
    protocol DefaultCleaningSummaryStore {
        func find(_ code: String) -> DefaultCleaningSummary?
        func save(_ item: DefaultCleaningSummary)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCleaningSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCleaningSummaryStore: DefaultCleaningSummaryStore {
        var items: [String: DefaultCleaningSummary]
        var order: [String]

        init(items: [String: DefaultCleaningSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCleaningSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCleaningSummary) {
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

        func list() -> [DefaultCleaningSummary] {
            var out: [DefaultCleaningSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCleaningSummaryStore() -> any DefaultCleaningSummaryStore {
        return MemoryDefaultCleaningSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCleaningSummaryStore: DefaultCleaningSummaryStore {
        var inner: MemoryDefaultCleaningSummaryStore
        var cache: TTLCache<DefaultCleaningSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCleaningSummaryStore, cache: TTLCache<DefaultCleaningSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCleaningSummary? {
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

        func save(_ item: DefaultCleaningSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCleaningSummary] {
            return inner.list()
        }
    }

    static func newCachedDefaultCleaningSummaryStore(_ inner: MemoryDefaultCleaningSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCleaningSummaryStore {
        return CachedDefaultCleaningSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default cleaning summaries. Empty fields match all.
    final class DefaultCleaningSummaryQuery {
        var source: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minScore: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCleaningSummary) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCleaningSummary]) -> [DefaultCleaningSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCleaningSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCleaningSummaries(_ store: any DefaultCleaningSummaryStore, query: DefaultCleaningSummaryQuery) -> [DefaultCleaningSummary] {
        return query.apply(store.list())
    }
}
