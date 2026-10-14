import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential tiers by code.
    protocol CredentialTierStore {
        func find(_ code: String) -> CredentialTier?
        func save(_ item: CredentialTier)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialTierStore: CredentialTierStore {
        var items: [String: CredentialTier]
        var order: [String]

        init(items: [String: CredentialTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialTier) {
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

        func list() -> [CredentialTier] {
            var out: [CredentialTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialTierStore() -> any CredentialTierStore {
        return MemoryCredentialTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialTierStore: CredentialTierStore {
        var inner: MemoryCredentialTierStore
        var cache: TTLCache<CredentialTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialTierStore, cache: TTLCache<CredentialTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialTier? {
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

        func save(_ item: CredentialTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialTier] {
            return inner.list()
        }
    }

    static func newCachedCredentialTierStore(_ inner: MemoryCredentialTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialTierStore {
        return CachedCredentialTierStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential tiers. Empty fields match all.
    final class CredentialTierQuery {
        var ward: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialTier) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialTier]) -> [CredentialTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialTiers(_ store: any CredentialTierStore, query: CredentialTierQuery) -> [CredentialTier] {
        return query.apply(store.list())
    }
}
