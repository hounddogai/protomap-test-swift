import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback goal rollups by code.
    protocol FallbackGoalRollupStore {
        func find(_ code: String) -> FallbackGoalRollup?
        func save(_ item: FallbackGoalRollup)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackGoalRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackGoalRollupStore: FallbackGoalRollupStore {
        var items: [String: FallbackGoalRollup]
        var order: [String]

        init(items: [String: FallbackGoalRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackGoalRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackGoalRollup) {
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

        func list() -> [FallbackGoalRollup] {
            var out: [FallbackGoalRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackGoalRollupStore() -> any FallbackGoalRollupStore {
        return MemoryFallbackGoalRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackGoalRollupStore: FallbackGoalRollupStore {
        var inner: MemoryFallbackGoalRollupStore
        var cache: TTLCache<FallbackGoalRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackGoalRollupStore, cache: TTLCache<FallbackGoalRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackGoalRollup? {
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

        func save(_ item: FallbackGoalRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackGoalRollup] {
            return inner.list()
        }
    }

    static func newCachedFallbackGoalRollupStore(_ inner: MemoryFallbackGoalRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackGoalRollupStore {
        return CachedFallbackGoalRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback goal rollups. Empty fields match all.
    final class FallbackGoalRollupQuery {
        var channel: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMargin: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackGoalRollup) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackGoalRollup]) -> [FallbackGoalRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackGoalRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackGoalRollups(_ store: any FallbackGoalRollupStore, query: FallbackGoalRollupQuery) -> [FallbackGoalRollup] {
        return query.apply(store.list())
    }
}
