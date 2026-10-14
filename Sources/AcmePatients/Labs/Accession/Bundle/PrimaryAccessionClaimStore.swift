import AcmePlatform
import Foundation

extension Labs {
    /// Keeps primary accession claims by code.
    protocol PrimaryAccessionClaimStore {
        func find(_ code: String) -> PrimaryAccessionClaim?
        func save(_ item: PrimaryAccessionClaim)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryAccessionClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryAccessionClaimStore: PrimaryAccessionClaimStore {
        var items: [String: PrimaryAccessionClaim]
        var order: [String]

        init(items: [String: PrimaryAccessionClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryAccessionClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryAccessionClaim) {
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

        func list() -> [PrimaryAccessionClaim] {
            var out: [PrimaryAccessionClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryAccessionClaimStore() -> any PrimaryAccessionClaimStore {
        return MemoryPrimaryAccessionClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryAccessionClaimStore: PrimaryAccessionClaimStore {
        var inner: MemoryPrimaryAccessionClaimStore
        var cache: TTLCache<PrimaryAccessionClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryAccessionClaimStore, cache: TTLCache<PrimaryAccessionClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryAccessionClaim? {
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

        func save(_ item: PrimaryAccessionClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryAccessionClaim] {
            return inner.list()
        }
    }

    static func newCachedPrimaryAccessionClaimStore(_ inner: MemoryPrimaryAccessionClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryAccessionClaimStore {
        return CachedPrimaryAccessionClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary accession claims. Empty fields match all.
    final class PrimaryAccessionClaimQuery {
        var category: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVersion: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryAccessionClaim) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [PrimaryAccessionClaim]) -> [PrimaryAccessionClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryAccessionClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryAccessionClaims(_ store: any PrimaryAccessionClaimStore, query: PrimaryAccessionClaimQuery) -> [PrimaryAccessionClaim] {
        return query.apply(store.list())
    }
}
