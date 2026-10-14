import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure summaries by code.
    protocol DisclosureSummaryStore {
        func find(_ code: String) -> DisclosureSummary?
        func save(_ item: DisclosureSummary)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureSummaryStore: DisclosureSummaryStore {
        var items: [String: DisclosureSummary]
        var order: [String]

        init(items: [String: DisclosureSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureSummary) {
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

        func list() -> [DisclosureSummary] {
            var out: [DisclosureSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureSummaryStore() -> any DisclosureSummaryStore {
        return MemoryDisclosureSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureSummaryStore: DisclosureSummaryStore {
        var inner: MemoryDisclosureSummaryStore
        var cache: TTLCache<DisclosureSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureSummaryStore, cache: TTLCache<DisclosureSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureSummary? {
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

        func save(_ item: DisclosureSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureSummary] {
            return inner.list()
        }
    }

    static func newCachedDisclosureSummaryStore(_ inner: MemoryDisclosureSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureSummaryStore {
        return CachedDisclosureSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure summaries. Empty fields match all.
    final class DisclosureSummaryQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureSummary) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureSummary]) -> [DisclosureSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureSummaries(_ store: any DisclosureSummaryStore, query: DisclosureSummaryQuery) -> [DisclosureSummary] {
        return query.apply(store.list())
    }
}
