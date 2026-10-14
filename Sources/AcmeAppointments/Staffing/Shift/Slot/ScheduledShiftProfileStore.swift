import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps scheduled shift profiles by code.
    protocol ScheduledShiftProfileStore {
        func find(_ code: String) -> ScheduledShiftProfile?
        func save(_ item: ScheduledShiftProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledShiftProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledShiftProfileStore: ScheduledShiftProfileStore {
        var items: [String: ScheduledShiftProfile]
        var order: [String]

        init(items: [String: ScheduledShiftProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledShiftProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledShiftProfile) {
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

        func list() -> [ScheduledShiftProfile] {
            var out: [ScheduledShiftProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledShiftProfileStore() -> any ScheduledShiftProfileStore {
        return MemoryScheduledShiftProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledShiftProfileStore: ScheduledShiftProfileStore {
        var inner: MemoryScheduledShiftProfileStore
        var cache: TTLCache<ScheduledShiftProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledShiftProfileStore, cache: TTLCache<ScheduledShiftProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledShiftProfile? {
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

        func save(_ item: ScheduledShiftProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledShiftProfile] {
            return inner.list()
        }
    }

    static func newCachedScheduledShiftProfileStore(_ inner: MemoryScheduledShiftProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledShiftProfileStore {
        return CachedScheduledShiftProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled shift profiles. Empty fields match all.
    final class ScheduledShiftProfileQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledShiftProfile) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledShiftProfile]) -> [ScheduledShiftProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledShiftProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledShiftProfiles(_ store: any ScheduledShiftProfileStore, query: ScheduledShiftProfileQuery) -> [ScheduledShiftProfile] {
        return query.apply(store.list())
    }
}
