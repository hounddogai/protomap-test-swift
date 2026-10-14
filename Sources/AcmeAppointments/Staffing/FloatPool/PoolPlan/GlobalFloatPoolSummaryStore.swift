import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global float pool summaries by code.
    protocol GlobalFloatPoolSummaryStore {
        func find(_ code: String) -> GlobalFloatPoolSummary?
        func save(_ item: GlobalFloatPoolSummary)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalFloatPoolSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalFloatPoolSummaryStore: GlobalFloatPoolSummaryStore {
        var items: [String: GlobalFloatPoolSummary]
        var order: [String]

        init(items: [String: GlobalFloatPoolSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalFloatPoolSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalFloatPoolSummary) {
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

        func list() -> [GlobalFloatPoolSummary] {
            var out: [GlobalFloatPoolSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalFloatPoolSummaryStore() -> any GlobalFloatPoolSummaryStore {
        return MemoryGlobalFloatPoolSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalFloatPoolSummaryStore: GlobalFloatPoolSummaryStore {
        var inner: MemoryGlobalFloatPoolSummaryStore
        var cache: TTLCache<GlobalFloatPoolSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalFloatPoolSummaryStore, cache: TTLCache<GlobalFloatPoolSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalFloatPoolSummary? {
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

        func save(_ item: GlobalFloatPoolSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalFloatPoolSummary] {
            return inner.list()
        }
    }

    static func newCachedGlobalFloatPoolSummaryStore(_ inner: MemoryGlobalFloatPoolSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalFloatPoolSummaryStore {
        return CachedGlobalFloatPoolSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global float pool summaries. Empty fields match all.
    final class GlobalFloatPoolSummaryQuery {
        var category: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalFloatPoolSummary) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalFloatPoolSummary]) -> [GlobalFloatPoolSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalFloatPoolSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalFloatPoolSummaries(_ store: any GlobalFloatPoolSummaryStore, query: GlobalFloatPoolSummaryQuery) -> [GlobalFloatPoolSummary] {
        return query.apply(store.list())
    }
}
