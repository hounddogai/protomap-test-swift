import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps manual float pool summaries by code.
    protocol ManualFloatPoolSummaryStore {
        func find(_ code: String) -> ManualFloatPoolSummary?
        func save(_ item: ManualFloatPoolSummary)
        func remove(_ code: String) -> Bool
        func list() -> [ManualFloatPoolSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualFloatPoolSummaryStore: ManualFloatPoolSummaryStore {
        var items: [String: ManualFloatPoolSummary]
        var order: [String]

        init(items: [String: ManualFloatPoolSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualFloatPoolSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualFloatPoolSummary) {
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

        func list() -> [ManualFloatPoolSummary] {
            var out: [ManualFloatPoolSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualFloatPoolSummaryStore() -> any ManualFloatPoolSummaryStore {
        return MemoryManualFloatPoolSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualFloatPoolSummaryStore: ManualFloatPoolSummaryStore {
        var inner: MemoryManualFloatPoolSummaryStore
        var cache: TTLCache<ManualFloatPoolSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualFloatPoolSummaryStore, cache: TTLCache<ManualFloatPoolSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualFloatPoolSummary? {
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

        func save(_ item: ManualFloatPoolSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualFloatPoolSummary] {
            return inner.list()
        }
    }

    static func newCachedManualFloatPoolSummaryStore(_ inner: MemoryManualFloatPoolSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualFloatPoolSummaryStore {
        return CachedManualFloatPoolSummaryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual float pool summaries. Empty fields match all.
    final class ManualFloatPoolSummaryQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualFloatPoolSummary) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ManualFloatPoolSummary]) -> [ManualFloatPoolSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualFloatPoolSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualFloatPoolSummaries(_ store: any ManualFloatPoolSummaryStore, query: ManualFloatPoolSummaryQuery) -> [ManualFloatPoolSummary] {
        return query.apply(store.list())
    }
}
