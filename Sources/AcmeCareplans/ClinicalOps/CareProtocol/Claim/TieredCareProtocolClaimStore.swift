import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps tiered care protocol claims by code.
    protocol TieredCareProtocolClaimStore {
        func find(_ code: String) -> TieredCareProtocolClaim?
        func save(_ item: TieredCareProtocolClaim)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCareProtocolClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCareProtocolClaimStore: TieredCareProtocolClaimStore {
        var items: [String: TieredCareProtocolClaim]
        var order: [String]

        init(items: [String: TieredCareProtocolClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCareProtocolClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCareProtocolClaim) {
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

        func list() -> [TieredCareProtocolClaim] {
            var out: [TieredCareProtocolClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCareProtocolClaimStore() -> any TieredCareProtocolClaimStore {
        return MemoryTieredCareProtocolClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCareProtocolClaimStore: TieredCareProtocolClaimStore {
        var inner: MemoryTieredCareProtocolClaimStore
        var cache: TTLCache<TieredCareProtocolClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCareProtocolClaimStore, cache: TTLCache<TieredCareProtocolClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCareProtocolClaim? {
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

        func save(_ item: TieredCareProtocolClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCareProtocolClaim] {
            return inner.list()
        }
    }

    static func newCachedTieredCareProtocolClaimStore(_ inner: MemoryTieredCareProtocolClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCareProtocolClaimStore {
        return CachedTieredCareProtocolClaimStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered care protocol claims. Empty fields match all.
    final class TieredCareProtocolClaimQuery {
        var category: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredCareProtocolClaim) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredCareProtocolClaim]) -> [TieredCareProtocolClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCareProtocolClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCareProtocolClaims(_ store: any TieredCareProtocolClaimStore, query: TieredCareProtocolClaimQuery) -> [TieredCareProtocolClaim] {
        return query.apply(store.list())
    }
}
