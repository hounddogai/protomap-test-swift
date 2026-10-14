import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result profiles by code.
    protocol ResultProfileStore {
        func find(_ code: String) -> ResultProfile?
        func save(_ item: ResultProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ResultProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultProfileStore: ResultProfileStore {
        var items: [String: ResultProfile]
        var order: [String]

        init(items: [String: ResultProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultProfile) {
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

        func list() -> [ResultProfile] {
            var out: [ResultProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultProfileStore() -> any ResultProfileStore {
        return MemoryResultProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultProfileStore: ResultProfileStore {
        var inner: MemoryResultProfileStore
        var cache: TTLCache<ResultProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultProfileStore, cache: TTLCache<ResultProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultProfile? {
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

        func save(_ item: ResultProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultProfile] {
            return inner.list()
        }
    }

    static func newCachedResultProfileStore(_ inner: MemoryResultProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultProfileStore {
        return CachedResultProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result profiles. Empty fields match all.
    final class ResultProfileQuery {
        var channel: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRetries: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultProfile) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultProfile]) -> [ResultProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultProfiles(_ store: any ResultProfileStore, query: ResultProfileQuery) -> [ResultProfile] {
        return query.apply(store.list())
    }
}
