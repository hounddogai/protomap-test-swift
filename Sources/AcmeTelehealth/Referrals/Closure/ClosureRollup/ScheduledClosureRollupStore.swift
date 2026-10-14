import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled closure rollups by code.
    protocol ScheduledClosureRollupStore {
        func find(_ code: String) -> ScheduledClosureRollup?
        func save(_ item: ScheduledClosureRollup)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledClosureRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledClosureRollupStore: ScheduledClosureRollupStore {
        var items: [String: ScheduledClosureRollup]
        var order: [String]

        init(items: [String: ScheduledClosureRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledClosureRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledClosureRollup) {
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

        func list() -> [ScheduledClosureRollup] {
            var out: [ScheduledClosureRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledClosureRollupStore() -> any ScheduledClosureRollupStore {
        return MemoryScheduledClosureRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledClosureRollupStore: ScheduledClosureRollupStore {
        var inner: MemoryScheduledClosureRollupStore
        var cache: TTLCache<ScheduledClosureRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledClosureRollupStore, cache: TTLCache<ScheduledClosureRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledClosureRollup? {
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

        func save(_ item: ScheduledClosureRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledClosureRollup] {
            return inner.list()
        }
    }

    static func newCachedScheduledClosureRollupStore(_ inner: MemoryScheduledClosureRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledClosureRollupStore {
        return CachedScheduledClosureRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled closure rollups. Empty fields match all.
    final class ScheduledClosureRollupQuery {
        var channel: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minWeight: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledClosureRollup) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ScheduledClosureRollup]) -> [ScheduledClosureRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledClosureRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledClosureRollups(_ store: any ScheduledClosureRollupStore, query: ScheduledClosureRollupQuery) -> [ScheduledClosureRollup] {
        return query.apply(store.list())
    }
}
