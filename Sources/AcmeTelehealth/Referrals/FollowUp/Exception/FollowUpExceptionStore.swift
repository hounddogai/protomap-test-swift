import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up exceptions by code.
    protocol FollowUpExceptionStore {
        func find(_ code: String) -> FollowUpException?
        func save(_ item: FollowUpException)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpExceptionStore: FollowUpExceptionStore {
        var items: [String: FollowUpException]
        var order: [String]

        init(items: [String: FollowUpException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpException) {
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

        func list() -> [FollowUpException] {
            var out: [FollowUpException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpExceptionStore() -> any FollowUpExceptionStore {
        return MemoryFollowUpExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpExceptionStore: FollowUpExceptionStore {
        var inner: MemoryFollowUpExceptionStore
        var cache: TTLCache<FollowUpException>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpExceptionStore, cache: TTLCache<FollowUpException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpException? {
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

        func save(_ item: FollowUpException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpException] {
            return inner.list()
        }
    }

    static func newCachedFollowUpExceptionStore(_ inner: MemoryFollowUpExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpExceptionStore {
        return CachedFollowUpExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up exceptions. Empty fields match all.
    final class FollowUpExceptionQuery {
        var channel: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minLimit: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpException) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [FollowUpException]) -> [FollowUpException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpExceptions(_ store: any FollowUpExceptionStore, query: FollowUpExceptionQuery) -> [FollowUpException] {
        return query.apply(store.list())
    }
}
