import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance summaries by code.
    protocol RemittanceSummaryStore {
        func find(_ code: String) -> RemittanceSummary?
        func save(_ item: RemittanceSummary)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceSummaryStore: RemittanceSummaryStore {
        var items: [String: RemittanceSummary]
        var order: [String]

        init(items: [String: RemittanceSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceSummary) {
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

        func list() -> [RemittanceSummary] {
            var out: [RemittanceSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceSummaryStore() -> any RemittanceSummaryStore {
        return MemoryRemittanceSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceSummaryStore: RemittanceSummaryStore {
        var inner: MemoryRemittanceSummaryStore
        var cache: TTLCache<RemittanceSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceSummaryStore, cache: TTLCache<RemittanceSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceSummary? {
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

        func save(_ item: RemittanceSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceSummary] {
            return inner.list()
        }
    }

    static func newCachedRemittanceSummaryStore(_ inner: MemoryRemittanceSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceSummaryStore {
        return CachedRemittanceSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance summaries. Empty fields match all.
    final class RemittanceSummaryQuery {
        var region: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minScore: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceSummary) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [RemittanceSummary]) -> [RemittanceSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceSummaries(_ store: any RemittanceSummaryStore, query: RemittanceSummaryQuery) -> [RemittanceSummary] {
        return query.apply(store.list())
    }
}
