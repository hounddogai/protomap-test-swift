import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps scheduled denial claims by code.
    protocol ScheduledDenialClaimStore {
        func find(_ code: String) -> ScheduledDenialClaim?
        func save(_ item: ScheduledDenialClaim)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledDenialClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledDenialClaimStore: ScheduledDenialClaimStore {
        var items: [String: ScheduledDenialClaim]
        var order: [String]

        init(items: [String: ScheduledDenialClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledDenialClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledDenialClaim) {
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

        func list() -> [ScheduledDenialClaim] {
            var out: [ScheduledDenialClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledDenialClaimStore() -> any ScheduledDenialClaimStore {
        return MemoryScheduledDenialClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledDenialClaimStore: ScheduledDenialClaimStore {
        var inner: MemoryScheduledDenialClaimStore
        var cache: TTLCache<ScheduledDenialClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledDenialClaimStore, cache: TTLCache<ScheduledDenialClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledDenialClaim? {
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

        func save(_ item: ScheduledDenialClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledDenialClaim] {
            return inner.list()
        }
    }

    static func newCachedScheduledDenialClaimStore(_ inner: MemoryScheduledDenialClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledDenialClaimStore {
        return CachedScheduledDenialClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled denial claims. Empty fields match all.
    final class ScheduledDenialClaimQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledDenialClaim) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledDenialClaim]) -> [ScheduledDenialClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledDenialClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledDenialClaims(_ store: any ScheduledDenialClaimStore, query: ScheduledDenialClaimQuery) -> [ScheduledDenialClaim] {
        return query.apply(store.list())
    }
}
