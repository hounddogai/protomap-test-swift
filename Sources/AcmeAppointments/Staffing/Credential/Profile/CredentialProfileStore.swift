import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential profiles by code.
    protocol CredentialProfileStore {
        func find(_ code: String) -> CredentialProfile?
        func save(_ item: CredentialProfile)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialProfileStore: CredentialProfileStore {
        var items: [String: CredentialProfile]
        var order: [String]

        init(items: [String: CredentialProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialProfile) {
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

        func list() -> [CredentialProfile] {
            var out: [CredentialProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialProfileStore() -> any CredentialProfileStore {
        return MemoryCredentialProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialProfileStore: CredentialProfileStore {
        var inner: MemoryCredentialProfileStore
        var cache: TTLCache<CredentialProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialProfileStore, cache: TTLCache<CredentialProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialProfile? {
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

        func save(_ item: CredentialProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialProfile] {
            return inner.list()
        }
    }

    static func newCachedCredentialProfileStore(_ inner: MemoryCredentialProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialProfileStore {
        return CachedCredentialProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential profiles. Empty fields match all.
    final class CredentialProfileQuery {
        var channel: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialProfile) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialProfile]) -> [CredentialProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialProfiles(_ store: any CredentialProfileStore, query: CredentialProfileQuery) -> [CredentialProfile] {
        return query.apply(store.list())
    }
}
