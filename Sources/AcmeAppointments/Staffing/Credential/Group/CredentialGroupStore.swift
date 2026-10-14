import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential groups by code.
    protocol CredentialGroupStore {
        func find(_ code: String) -> CredentialGroup?
        func save(_ item: CredentialGroup)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialGroupStore: CredentialGroupStore {
        var items: [String: CredentialGroup]
        var order: [String]

        init(items: [String: CredentialGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialGroup) {
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

        func list() -> [CredentialGroup] {
            var out: [CredentialGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialGroupStore() -> any CredentialGroupStore {
        return MemoryCredentialGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialGroupStore: CredentialGroupStore {
        var inner: MemoryCredentialGroupStore
        var cache: TTLCache<CredentialGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialGroupStore, cache: TTLCache<CredentialGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialGroup? {
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

        func save(_ item: CredentialGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialGroup] {
            return inner.list()
        }
    }

    static func newCachedCredentialGroupStore(_ inner: MemoryCredentialGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialGroupStore {
        return CachedCredentialGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential groups. Empty fields match all.
    final class CredentialGroupQuery {
        var channel: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialGroup) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialGroup]) -> [CredentialGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialGroups(_ store: any CredentialGroupStore, query: CredentialGroupQuery) -> [CredentialGroup] {
        return query.apply(store.list())
    }
}
