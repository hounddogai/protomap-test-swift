import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation groups by code.
    protocol RevocationGroupStore {
        func find(_ code: String) -> RevocationGroup?
        func save(_ item: RevocationGroup)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationGroupStore: RevocationGroupStore {
        var items: [String: RevocationGroup]
        var order: [String]

        init(items: [String: RevocationGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationGroup) {
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

        func list() -> [RevocationGroup] {
            var out: [RevocationGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationGroupStore() -> any RevocationGroupStore {
        return MemoryRevocationGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationGroupStore: RevocationGroupStore {
        var inner: MemoryRevocationGroupStore
        var cache: TTLCache<RevocationGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationGroupStore, cache: TTLCache<RevocationGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationGroup? {
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

        func save(_ item: RevocationGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationGroup] {
            return inner.list()
        }
    }

    static func newCachedRevocationGroupStore(_ inner: MemoryRevocationGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationGroupStore {
        return CachedRevocationGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation groups. Empty fields match all.
    final class RevocationGroupQuery {
        var ward: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationGroup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationGroup]) -> [RevocationGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationGroups(_ store: any RevocationGroupStore, query: RevocationGroupQuery) -> [RevocationGroup] {
        return query.apply(store.list())
    }
}
