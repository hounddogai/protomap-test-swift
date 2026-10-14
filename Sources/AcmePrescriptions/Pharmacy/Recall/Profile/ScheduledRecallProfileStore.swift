import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps scheduled recall profiles by code.
    protocol ScheduledRecallProfileStore {
        func find(_ code: String) -> ScheduledRecallProfile?
        func save(_ item: ScheduledRecallProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledRecallProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledRecallProfileStore: ScheduledRecallProfileStore {
        var items: [String: ScheduledRecallProfile]
        var order: [String]

        init(items: [String: ScheduledRecallProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledRecallProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledRecallProfile) {
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

        func list() -> [ScheduledRecallProfile] {
            var out: [ScheduledRecallProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledRecallProfileStore() -> any ScheduledRecallProfileStore {
        return MemoryScheduledRecallProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledRecallProfileStore: ScheduledRecallProfileStore {
        var inner: MemoryScheduledRecallProfileStore
        var cache: TTLCache<ScheduledRecallProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledRecallProfileStore, cache: TTLCache<ScheduledRecallProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledRecallProfile? {
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

        func save(_ item: ScheduledRecallProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledRecallProfile] {
            return inner.list()
        }
    }

    static func newCachedScheduledRecallProfileStore(_ inner: MemoryScheduledRecallProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledRecallProfileStore {
        return CachedScheduledRecallProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled recall profiles. Empty fields match all.
    final class ScheduledRecallProfileQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledRecallProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledRecallProfile]) -> [ScheduledRecallProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledRecallProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledRecallProfiles(_ store: any ScheduledRecallProfileStore, query: ScheduledRecallProfileQuery) -> [ScheduledRecallProfile] {
        return query.apply(store.list())
    }
}
