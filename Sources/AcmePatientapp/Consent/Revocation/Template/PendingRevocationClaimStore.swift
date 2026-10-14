import AcmePlatform
import Foundation

extension Consent {
    /// Keeps pending revocation claims by code.
    protocol PendingRevocationClaimStore {
        func find(_ code: String) -> PendingRevocationClaim?
        func save(_ item: PendingRevocationClaim)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRevocationClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRevocationClaimStore: PendingRevocationClaimStore {
        var items: [String: PendingRevocationClaim]
        var order: [String]

        init(items: [String: PendingRevocationClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRevocationClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRevocationClaim) {
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

        func list() -> [PendingRevocationClaim] {
            var out: [PendingRevocationClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRevocationClaimStore() -> any PendingRevocationClaimStore {
        return MemoryPendingRevocationClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRevocationClaimStore: PendingRevocationClaimStore {
        var inner: MemoryPendingRevocationClaimStore
        var cache: TTLCache<PendingRevocationClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRevocationClaimStore, cache: TTLCache<PendingRevocationClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRevocationClaim? {
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

        func save(_ item: PendingRevocationClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRevocationClaim] {
            return inner.list()
        }
    }

    static func newCachedPendingRevocationClaimStore(_ inner: MemoryPendingRevocationClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRevocationClaimStore {
        return CachedPendingRevocationClaimStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending revocation claims. Empty fields match all.
    final class PendingRevocationClaimQuery {
        var region: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minVersion: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRevocationClaim) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingRevocationClaim]) -> [PendingRevocationClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRevocationClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRevocationClaims(_ store: any PendingRevocationClaimStore, query: PendingRevocationClaimQuery) -> [PendingRevocationClaim] {
        return query.apply(store.list())
    }
}
