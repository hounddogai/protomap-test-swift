import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient read summaries by code.
    protocol LenientReadSummaryStore {
        func find(_ code: String) -> LenientReadSummary?
        func save(_ item: LenientReadSummary)
        func remove(_ code: String) -> Bool
        func list() -> [LenientReadSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientReadSummaryStore: LenientReadSummaryStore {
        var items: [String: LenientReadSummary]
        var order: [String]

        init(items: [String: LenientReadSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientReadSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientReadSummary) {
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

        func list() -> [LenientReadSummary] {
            var out: [LenientReadSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientReadSummaryStore() -> any LenientReadSummaryStore {
        return MemoryLenientReadSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientReadSummaryStore: LenientReadSummaryStore {
        var inner: MemoryLenientReadSummaryStore
        var cache: TTLCache<LenientReadSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientReadSummaryStore, cache: TTLCache<LenientReadSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientReadSummary? {
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

        func save(_ item: LenientReadSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientReadSummary] {
            return inner.list()
        }
    }

    static func newCachedLenientReadSummaryStore(_ inner: MemoryLenientReadSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientReadSummaryStore {
        return CachedLenientReadSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient read summaries. Empty fields match all.
    final class LenientReadSummaryQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientReadSummary) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientReadSummary]) -> [LenientReadSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientReadSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientReadSummaries(_ store: any LenientReadSummaryStore, query: LenientReadSummaryQuery) -> [LenientReadSummary] {
        return query.apply(store.list())
    }
}
