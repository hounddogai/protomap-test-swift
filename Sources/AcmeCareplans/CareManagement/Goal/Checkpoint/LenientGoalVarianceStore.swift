import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient goal variances by code.
    protocol LenientGoalVarianceStore {
        func find(_ code: String) -> LenientGoalVariance?
        func save(_ item: LenientGoalVariance)
        func remove(_ code: String) -> Bool
        func list() -> [LenientGoalVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientGoalVarianceStore: LenientGoalVarianceStore {
        var items: [String: LenientGoalVariance]
        var order: [String]

        init(items: [String: LenientGoalVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientGoalVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientGoalVariance) {
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

        func list() -> [LenientGoalVariance] {
            var out: [LenientGoalVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientGoalVarianceStore() -> any LenientGoalVarianceStore {
        return MemoryLenientGoalVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientGoalVarianceStore: LenientGoalVarianceStore {
        var inner: MemoryLenientGoalVarianceStore
        var cache: TTLCache<LenientGoalVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientGoalVarianceStore, cache: TTLCache<LenientGoalVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientGoalVariance? {
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

        func save(_ item: LenientGoalVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientGoalVariance] {
            return inner.list()
        }
    }

    static func newCachedLenientGoalVarianceStore(_ inner: MemoryLenientGoalVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientGoalVarianceStore {
        return CachedLenientGoalVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient goal variances. Empty fields match all.
    final class LenientGoalVarianceQuery {
        var channel: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientGoalVariance) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [LenientGoalVariance]) -> [LenientGoalVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientGoalVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientGoalVariances(_ store: any LenientGoalVarianceStore, query: LenientGoalVarianceQuery) -> [LenientGoalVariance] {
        return query.apply(store.list())
    }
}
