import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim requests by code.
    protocol ClaimRequestStore {
        func find(_ code: String) -> ClaimRequest?
        func save(_ item: ClaimRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimRequestStore: ClaimRequestStore {
        var items: [String: ClaimRequest]
        var order: [String]

        init(items: [String: ClaimRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimRequest) {
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

        func list() -> [ClaimRequest] {
            var out: [ClaimRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimRequestStore() -> any ClaimRequestStore {
        return MemoryClaimRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimRequestStore: ClaimRequestStore {
        var inner: MemoryClaimRequestStore
        var cache: TTLCache<ClaimRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimRequestStore, cache: TTLCache<ClaimRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimRequest? {
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

        func save(_ item: ClaimRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimRequest] {
            return inner.list()
        }
    }

    static func newCachedClaimRequestStore(_ inner: MemoryClaimRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimRequestStore {
        return CachedClaimRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim requests. Empty fields match all.
    final class ClaimRequestQuery {
        var facility: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimRequest) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimRequest]) -> [ClaimRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimRequests(_ store: any ClaimRequestStore, query: ClaimRequestQuery) -> [ClaimRequest] {
        return query.apply(store.list())
    }
}
