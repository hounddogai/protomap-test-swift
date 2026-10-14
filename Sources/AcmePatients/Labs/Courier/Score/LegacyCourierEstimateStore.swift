import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy courier estimates by code.
    protocol LegacyCourierEstimateStore {
        func find(_ code: String) -> LegacyCourierEstimate?
        func save(_ item: LegacyCourierEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCourierEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCourierEstimateStore: LegacyCourierEstimateStore {
        var items: [String: LegacyCourierEstimate]
        var order: [String]

        init(items: [String: LegacyCourierEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCourierEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCourierEstimate) {
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

        func list() -> [LegacyCourierEstimate] {
            var out: [LegacyCourierEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCourierEstimateStore() -> any LegacyCourierEstimateStore {
        return MemoryLegacyCourierEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCourierEstimateStore: LegacyCourierEstimateStore {
        var inner: MemoryLegacyCourierEstimateStore
        var cache: TTLCache<LegacyCourierEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCourierEstimateStore, cache: TTLCache<LegacyCourierEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCourierEstimate? {
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

        func save(_ item: LegacyCourierEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCourierEstimate] {
            return inner.list()
        }
    }

    static func newCachedLegacyCourierEstimateStore(_ inner: MemoryLegacyCourierEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCourierEstimateStore {
        return CachedLegacyCourierEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy courier estimates. Empty fields match all.
    final class LegacyCourierEstimateQuery {
        var channel: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minBudget: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCourierEstimate) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyCourierEstimate]) -> [LegacyCourierEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCourierEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCourierEstimates(_ store: any LegacyCourierEstimateStore, query: LegacyCourierEstimateQuery) -> [LegacyCourierEstimate] {
        return query.apply(store.list())
    }
}
