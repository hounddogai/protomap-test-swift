import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol claims by code.
    protocol CareProtocolClaimStore {
        func find(_ code: String) -> CareProtocolClaim?
        func save(_ item: CareProtocolClaim)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolClaimStore: CareProtocolClaimStore {
        var items: [String: CareProtocolClaim]
        var order: [String]

        init(items: [String: CareProtocolClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolClaim) {
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

        func list() -> [CareProtocolClaim] {
            var out: [CareProtocolClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolClaimStore() -> any CareProtocolClaimStore {
        return MemoryCareProtocolClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolClaimStore: CareProtocolClaimStore {
        var inner: MemoryCareProtocolClaimStore
        var cache: TTLCache<CareProtocolClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolClaimStore, cache: TTLCache<CareProtocolClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolClaim? {
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

        func save(_ item: CareProtocolClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolClaim] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolClaimStore(_ inner: MemoryCareProtocolClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolClaimStore {
        return CachedCareProtocolClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol claims. Empty fields match all.
    final class CareProtocolClaimQuery {
        var segment: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minPriority: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolClaim) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolClaim]) -> [CareProtocolClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolClaims(_ store: any CareProtocolClaimStore, query: CareProtocolClaimQuery) -> [CareProtocolClaim] {
        return query.apply(store.list())
    }
}
