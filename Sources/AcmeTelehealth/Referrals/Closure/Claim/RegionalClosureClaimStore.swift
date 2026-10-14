import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional closure claims by code.
    protocol RegionalClosureClaimStore {
        func find(_ code: String) -> RegionalClosureClaim?
        func save(_ item: RegionalClosureClaim)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalClosureClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalClosureClaimStore: RegionalClosureClaimStore {
        var items: [String: RegionalClosureClaim]
        var order: [String]

        init(items: [String: RegionalClosureClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalClosureClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalClosureClaim) {
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

        func list() -> [RegionalClosureClaim] {
            var out: [RegionalClosureClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalClosureClaimStore() -> any RegionalClosureClaimStore {
        return MemoryRegionalClosureClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalClosureClaimStore: RegionalClosureClaimStore {
        var inner: MemoryRegionalClosureClaimStore
        var cache: TTLCache<RegionalClosureClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalClosureClaimStore, cache: TTLCache<RegionalClosureClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalClosureClaim? {
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

        func save(_ item: RegionalClosureClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalClosureClaim] {
            return inner.list()
        }
    }

    static func newCachedRegionalClosureClaimStore(_ inner: MemoryRegionalClosureClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalClosureClaimStore {
        return CachedRegionalClosureClaimStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional closure claims. Empty fields match all.
    final class RegionalClosureClaimQuery {
        var channel: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalClosureClaim) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalClosureClaim]) -> [RegionalClosureClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalClosureClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalClosureClaims(_ store: any RegionalClosureClaimStore, query: RegionalClosureClaimQuery) -> [RegionalClosureClaim] {
        return query.apply(store.list())
    }
}
