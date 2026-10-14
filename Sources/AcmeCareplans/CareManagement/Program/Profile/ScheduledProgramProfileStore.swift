import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps scheduled program profiles by code.
    protocol ScheduledProgramProfileStore {
        func find(_ code: String) -> ScheduledProgramProfile?
        func save(_ item: ScheduledProgramProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledProgramProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledProgramProfileStore: ScheduledProgramProfileStore {
        var items: [String: ScheduledProgramProfile]
        var order: [String]

        init(items: [String: ScheduledProgramProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledProgramProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledProgramProfile) {
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

        func list() -> [ScheduledProgramProfile] {
            var out: [ScheduledProgramProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledProgramProfileStore() -> any ScheduledProgramProfileStore {
        return MemoryScheduledProgramProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledProgramProfileStore: ScheduledProgramProfileStore {
        var inner: MemoryScheduledProgramProfileStore
        var cache: TTLCache<ScheduledProgramProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledProgramProfileStore, cache: TTLCache<ScheduledProgramProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledProgramProfile? {
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

        func save(_ item: ScheduledProgramProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledProgramProfile] {
            return inner.list()
        }
    }

    static func newCachedScheduledProgramProfileStore(_ inner: MemoryScheduledProgramProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledProgramProfileStore {
        return CachedScheduledProgramProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled program profiles. Empty fields match all.
    final class ScheduledProgramProfileQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledProgramProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledProgramProfile]) -> [ScheduledProgramProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledProgramProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledProgramProfiles(_ store: any ScheduledProgramProfileStore, query: ScheduledProgramProfileQuery) -> [ScheduledProgramProfile] {
        return query.apply(store.list())
    }
}
