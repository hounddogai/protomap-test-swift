import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim overrides by code.
    protocol ClaimOverrideStore {
        func find(_ code: String) -> ClaimOverride?
        func save(_ item: ClaimOverride)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimOverrideStore: ClaimOverrideStore {
        var items: [String: ClaimOverride]
        var order: [String]

        init(items: [String: ClaimOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimOverride) {
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

        func list() -> [ClaimOverride] {
            var out: [ClaimOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimOverrideStore() -> any ClaimOverrideStore {
        return MemoryClaimOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimOverrideStore: ClaimOverrideStore {
        var inner: MemoryClaimOverrideStore
        var cache: TTLCache<ClaimOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimOverrideStore, cache: TTLCache<ClaimOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimOverride? {
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

        func save(_ item: ClaimOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimOverride] {
            return inner.list()
        }
    }

    static func newCachedClaimOverrideStore(_ inner: MemoryClaimOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimOverrideStore {
        return CachedClaimOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim overrides. Empty fields match all.
    final class ClaimOverrideQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimOverride]) -> [ClaimOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimOverrides(_ store: any ClaimOverrideStore, query: ClaimOverrideQuery) -> [ClaimOverride] {
        return query.apply(store.list())
    }
}
