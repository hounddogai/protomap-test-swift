import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps strict worklist claims by code.
    protocol StrictWorklistClaimStore {
        func find(_ code: String) -> StrictWorklistClaim?
        func save(_ item: StrictWorklistClaim)
        func remove(_ code: String) -> Bool
        func list() -> [StrictWorklistClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictWorklistClaimStore: StrictWorklistClaimStore {
        var items: [String: StrictWorklistClaim]
        var order: [String]

        init(items: [String: StrictWorklistClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictWorklistClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictWorklistClaim) {
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

        func list() -> [StrictWorklistClaim] {
            var out: [StrictWorklistClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictWorklistClaimStore() -> any StrictWorklistClaimStore {
        return MemoryStrictWorklistClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictWorklistClaimStore: StrictWorklistClaimStore {
        var inner: MemoryStrictWorklistClaimStore
        var cache: TTLCache<StrictWorklistClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictWorklistClaimStore, cache: TTLCache<StrictWorklistClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictWorklistClaim? {
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

        func save(_ item: StrictWorklistClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictWorklistClaim] {
            return inner.list()
        }
    }

    static func newCachedStrictWorklistClaimStore(_ inner: MemoryStrictWorklistClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictWorklistClaimStore {
        return CachedStrictWorklistClaimStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict worklist claims. Empty fields match all.
    final class StrictWorklistClaimQuery {
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

        func matches(_ item: StrictWorklistClaim) -> Bool {
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

        func apply(_ items: [StrictWorklistClaim]) -> [StrictWorklistClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictWorklistClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictWorklistClaims(_ store: any StrictWorklistClaimStore, query: StrictWorklistClaimQuery) -> [StrictWorklistClaim] {
        return query.apply(store.list())
    }
}
