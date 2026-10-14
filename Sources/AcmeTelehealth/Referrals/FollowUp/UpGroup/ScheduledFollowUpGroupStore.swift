import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled follow up groups by code.
    protocol ScheduledFollowUpGroupStore {
        func find(_ code: String) -> ScheduledFollowUpGroup?
        func save(_ item: ScheduledFollowUpGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledFollowUpGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledFollowUpGroupStore: ScheduledFollowUpGroupStore {
        var items: [String: ScheduledFollowUpGroup]
        var order: [String]

        init(items: [String: ScheduledFollowUpGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledFollowUpGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledFollowUpGroup) {
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

        func list() -> [ScheduledFollowUpGroup] {
            var out: [ScheduledFollowUpGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledFollowUpGroupStore() -> any ScheduledFollowUpGroupStore {
        return MemoryScheduledFollowUpGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledFollowUpGroupStore: ScheduledFollowUpGroupStore {
        var inner: MemoryScheduledFollowUpGroupStore
        var cache: TTLCache<ScheduledFollowUpGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledFollowUpGroupStore, cache: TTLCache<ScheduledFollowUpGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledFollowUpGroup? {
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

        func save(_ item: ScheduledFollowUpGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledFollowUpGroup] {
            return inner.list()
        }
    }

    static func newCachedScheduledFollowUpGroupStore(_ inner: MemoryScheduledFollowUpGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledFollowUpGroupStore {
        return CachedScheduledFollowUpGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled follow up groups. Empty fields match all.
    final class ScheduledFollowUpGroupQuery {
        var segment: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledFollowUpGroup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledFollowUpGroup]) -> [ScheduledFollowUpGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledFollowUpGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledFollowUpGroups(_ store: any ScheduledFollowUpGroupStore, query: ScheduledFollowUpGroupQuery) -> [ScheduledFollowUpGroup] {
        return query.apply(store.list())
    }
}
