import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled follow up cycles by code.
    protocol ScheduledFollowUpCycleStore {
        func find(_ code: String) -> ScheduledFollowUpCycle?
        func save(_ item: ScheduledFollowUpCycle)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledFollowUpCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledFollowUpCycleStore: ScheduledFollowUpCycleStore {
        var items: [String: ScheduledFollowUpCycle]
        var order: [String]

        init(items: [String: ScheduledFollowUpCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledFollowUpCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledFollowUpCycle) {
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

        func list() -> [ScheduledFollowUpCycle] {
            var out: [ScheduledFollowUpCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledFollowUpCycleStore() -> any ScheduledFollowUpCycleStore {
        return MemoryScheduledFollowUpCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledFollowUpCycleStore: ScheduledFollowUpCycleStore {
        var inner: MemoryScheduledFollowUpCycleStore
        var cache: TTLCache<ScheduledFollowUpCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledFollowUpCycleStore, cache: TTLCache<ScheduledFollowUpCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledFollowUpCycle? {
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

        func save(_ item: ScheduledFollowUpCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledFollowUpCycle] {
            return inner.list()
        }
    }

    static func newCachedScheduledFollowUpCycleStore(_ inner: MemoryScheduledFollowUpCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledFollowUpCycleStore {
        return CachedScheduledFollowUpCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled follow up cycles. Empty fields match all.
    final class ScheduledFollowUpCycleQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledFollowUpCycle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledFollowUpCycle]) -> [ScheduledFollowUpCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledFollowUpCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledFollowUpCycles(_ store: any ScheduledFollowUpCycleStore, query: ScheduledFollowUpCycleQuery) -> [ScheduledFollowUpCycle] {
        return query.apply(store.list())
    }
}
