import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps scheduled statement profiles by code.
    protocol ScheduledStatementProfileStore {
        func find(_ code: String) -> ScheduledStatementProfile?
        func save(_ item: ScheduledStatementProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledStatementProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledStatementProfileStore: ScheduledStatementProfileStore {
        var items: [String: ScheduledStatementProfile]
        var order: [String]

        init(items: [String: ScheduledStatementProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledStatementProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledStatementProfile) {
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

        func list() -> [ScheduledStatementProfile] {
            var out: [ScheduledStatementProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledStatementProfileStore() -> any ScheduledStatementProfileStore {
        return MemoryScheduledStatementProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledStatementProfileStore: ScheduledStatementProfileStore {
        var inner: MemoryScheduledStatementProfileStore
        var cache: TTLCache<ScheduledStatementProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledStatementProfileStore, cache: TTLCache<ScheduledStatementProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledStatementProfile? {
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

        func save(_ item: ScheduledStatementProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledStatementProfile] {
            return inner.list()
        }
    }

    static func newCachedScheduledStatementProfileStore(_ inner: MemoryScheduledStatementProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledStatementProfileStore {
        return CachedScheduledStatementProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled statement profiles. Empty fields match all.
    final class ScheduledStatementProfileQuery {
        var channel: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledStatementProfile) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ScheduledStatementProfile]) -> [ScheduledStatementProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledStatementProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledStatementProfiles(_ store: any ScheduledStatementProfileStore, query: ScheduledStatementProfileQuery) -> [ScheduledStatementProfile] {
        return query.apply(store.list())
    }
}
