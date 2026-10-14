import AcmePlatform
import Foundation

extension Consent {
    /// Keeps pending disclosure claims by code.
    protocol PendingDisclosureClaimStore {
        func find(_ code: String) -> PendingDisclosureClaim?
        func save(_ item: PendingDisclosureClaim)
        func remove(_ code: String) -> Bool
        func list() -> [PendingDisclosureClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingDisclosureClaimStore: PendingDisclosureClaimStore {
        var items: [String: PendingDisclosureClaim]
        var order: [String]

        init(items: [String: PendingDisclosureClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingDisclosureClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingDisclosureClaim) {
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

        func list() -> [PendingDisclosureClaim] {
            var out: [PendingDisclosureClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingDisclosureClaimStore() -> any PendingDisclosureClaimStore {
        return MemoryPendingDisclosureClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingDisclosureClaimStore: PendingDisclosureClaimStore {
        var inner: MemoryPendingDisclosureClaimStore
        var cache: TTLCache<PendingDisclosureClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingDisclosureClaimStore, cache: TTLCache<PendingDisclosureClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingDisclosureClaim? {
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

        func save(_ item: PendingDisclosureClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingDisclosureClaim] {
            return inner.list()
        }
    }

    static func newCachedPendingDisclosureClaimStore(_ inner: MemoryPendingDisclosureClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingDisclosureClaimStore {
        return CachedPendingDisclosureClaimStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending disclosure claims. Empty fields match all.
    final class PendingDisclosureClaimQuery {
        var country: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingDisclosureClaim) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [PendingDisclosureClaim]) -> [PendingDisclosureClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingDisclosureClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingDisclosureClaims(_ store: any PendingDisclosureClaimStore, query: PendingDisclosureClaimQuery) -> [PendingDisclosureClaim] {
        return query.apply(store.list())
    }
}
