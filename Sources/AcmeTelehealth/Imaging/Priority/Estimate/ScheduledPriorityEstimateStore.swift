import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps scheduled priority estimates by code.
    protocol ScheduledPriorityEstimateStore {
        func find(_ code: String) -> ScheduledPriorityEstimate?
        func save(_ item: ScheduledPriorityEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledPriorityEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledPriorityEstimateStore: ScheduledPriorityEstimateStore {
        var items: [String: ScheduledPriorityEstimate]
        var order: [String]

        init(items: [String: ScheduledPriorityEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledPriorityEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledPriorityEstimate) {
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

        func list() -> [ScheduledPriorityEstimate] {
            var out: [ScheduledPriorityEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledPriorityEstimateStore() -> any ScheduledPriorityEstimateStore {
        return MemoryScheduledPriorityEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledPriorityEstimateStore: ScheduledPriorityEstimateStore {
        var inner: MemoryScheduledPriorityEstimateStore
        var cache: TTLCache<ScheduledPriorityEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledPriorityEstimateStore, cache: TTLCache<ScheduledPriorityEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledPriorityEstimate? {
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

        func save(_ item: ScheduledPriorityEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledPriorityEstimate] {
            return inner.list()
        }
    }

    static func newCachedScheduledPriorityEstimateStore(_ inner: MemoryScheduledPriorityEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledPriorityEstimateStore {
        return CachedScheduledPriorityEstimateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled priority estimates. Empty fields match all.
    final class ScheduledPriorityEstimateQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledPriorityEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledPriorityEstimate]) -> [ScheduledPriorityEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledPriorityEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledPriorityEstimates(_ store: any ScheduledPriorityEstimateStore, query: ScheduledPriorityEstimateQuery) -> [ScheduledPriorityEstimate] {
        return query.apply(store.list())
    }
}
