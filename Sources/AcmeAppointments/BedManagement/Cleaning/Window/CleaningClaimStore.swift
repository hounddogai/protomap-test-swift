import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning claims by code.
    protocol CleaningClaimStore {
        func find(_ code: String) -> CleaningClaim?
        func save(_ item: CleaningClaim)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningClaimStore: CleaningClaimStore {
        var items: [String: CleaningClaim]
        var order: [String]

        init(items: [String: CleaningClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningClaim) {
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

        func list() -> [CleaningClaim] {
            var out: [CleaningClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningClaimStore() -> any CleaningClaimStore {
        return MemoryCleaningClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningClaimStore: CleaningClaimStore {
        var inner: MemoryCleaningClaimStore
        var cache: TTLCache<CleaningClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningClaimStore, cache: TTLCache<CleaningClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningClaim? {
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

        func save(_ item: CleaningClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningClaim] {
            return inner.list()
        }
    }

    static func newCachedCleaningClaimStore(_ inner: MemoryCleaningClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningClaimStore {
        return CachedCleaningClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning claims. Empty fields match all.
    final class CleaningClaimQuery {
        var category: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningClaim) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningClaim]) -> [CleaningClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningClaims(_ store: any CleaningClaimStore, query: CleaningClaimQuery) -> [CleaningClaim] {
        return query.apply(store.list())
    }
}
