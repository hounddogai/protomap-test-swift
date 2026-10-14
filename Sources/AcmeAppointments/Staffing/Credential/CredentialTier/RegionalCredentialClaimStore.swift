import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional credential claims by code.
    protocol RegionalCredentialClaimStore {
        func find(_ code: String) -> RegionalCredentialClaim?
        func save(_ item: RegionalCredentialClaim)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalCredentialClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalCredentialClaimStore: RegionalCredentialClaimStore {
        var items: [String: RegionalCredentialClaim]
        var order: [String]

        init(items: [String: RegionalCredentialClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalCredentialClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalCredentialClaim) {
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

        func list() -> [RegionalCredentialClaim] {
            var out: [RegionalCredentialClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalCredentialClaimStore() -> any RegionalCredentialClaimStore {
        return MemoryRegionalCredentialClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalCredentialClaimStore: RegionalCredentialClaimStore {
        var inner: MemoryRegionalCredentialClaimStore
        var cache: TTLCache<RegionalCredentialClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalCredentialClaimStore, cache: TTLCache<RegionalCredentialClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalCredentialClaim? {
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

        func save(_ item: RegionalCredentialClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalCredentialClaim] {
            return inner.list()
        }
    }

    static func newCachedRegionalCredentialClaimStore(_ inner: MemoryRegionalCredentialClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalCredentialClaimStore {
        return CachedRegionalCredentialClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional credential claims. Empty fields match all.
    final class RegionalCredentialClaimQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalCredentialClaim) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalCredentialClaim]) -> [RegionalCredentialClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalCredentialClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalCredentialClaims(_ store: any RegionalCredentialClaimStore, query: RegionalCredentialClaimQuery) -> [RegionalCredentialClaim] {
        return query.apply(store.list())
    }
}
