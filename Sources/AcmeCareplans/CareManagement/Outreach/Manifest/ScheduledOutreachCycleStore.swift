import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps scheduled outreach cycles by code.
    protocol ScheduledOutreachCycleStore {
        func find(_ code: String) -> ScheduledOutreachCycle?
        func save(_ item: ScheduledOutreachCycle)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledOutreachCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledOutreachCycleStore: ScheduledOutreachCycleStore {
        var items: [String: ScheduledOutreachCycle]
        var order: [String]

        init(items: [String: ScheduledOutreachCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledOutreachCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledOutreachCycle) {
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

        func list() -> [ScheduledOutreachCycle] {
            var out: [ScheduledOutreachCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledOutreachCycleStore() -> any ScheduledOutreachCycleStore {
        return MemoryScheduledOutreachCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledOutreachCycleStore: ScheduledOutreachCycleStore {
        var inner: MemoryScheduledOutreachCycleStore
        var cache: TTLCache<ScheduledOutreachCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledOutreachCycleStore, cache: TTLCache<ScheduledOutreachCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledOutreachCycle? {
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

        func save(_ item: ScheduledOutreachCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledOutreachCycle] {
            return inner.list()
        }
    }

    static func newCachedScheduledOutreachCycleStore(_ inner: MemoryScheduledOutreachCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledOutreachCycleStore {
        return CachedScheduledOutreachCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled outreach cycles. Empty fields match all.
    final class ScheduledOutreachCycleQuery {
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

        func matches(_ item: ScheduledOutreachCycle) -> Bool {
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

        func apply(_ items: [ScheduledOutreachCycle]) -> [ScheduledOutreachCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledOutreachCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledOutreachCycles(_ store: any ScheduledOutreachCycleStore, query: ScheduledOutreachCycleQuery) -> [ScheduledOutreachCycle] {
        return query.apply(store.list())
    }
}
