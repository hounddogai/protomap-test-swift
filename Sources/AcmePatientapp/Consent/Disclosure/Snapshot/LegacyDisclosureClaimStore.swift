import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy disclosure claims by code.
    protocol LegacyDisclosureClaimStore {
        func find(_ code: String) -> LegacyDisclosureClaim?
        func save(_ item: LegacyDisclosureClaim)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyDisclosureClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyDisclosureClaimStore: LegacyDisclosureClaimStore {
        var items: [String: LegacyDisclosureClaim]
        var order: [String]

        init(items: [String: LegacyDisclosureClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyDisclosureClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyDisclosureClaim) {
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

        func list() -> [LegacyDisclosureClaim] {
            var out: [LegacyDisclosureClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyDisclosureClaimStore() -> any LegacyDisclosureClaimStore {
        return MemoryLegacyDisclosureClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyDisclosureClaimStore: LegacyDisclosureClaimStore {
        var inner: MemoryLegacyDisclosureClaimStore
        var cache: TTLCache<LegacyDisclosureClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyDisclosureClaimStore, cache: TTLCache<LegacyDisclosureClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyDisclosureClaim? {
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

        func save(_ item: LegacyDisclosureClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyDisclosureClaim] {
            return inner.list()
        }
    }

    static func newCachedLegacyDisclosureClaimStore(_ inner: MemoryLegacyDisclosureClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyDisclosureClaimStore {
        return CachedLegacyDisclosureClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy disclosure claims. Empty fields match all.
    final class LegacyDisclosureClaimQuery {
        var label: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCost: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyDisclosureClaim) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyDisclosureClaim]) -> [LegacyDisclosureClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyDisclosureClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyDisclosureClaims(_ store: any LegacyDisclosureClaimStore, query: LegacyDisclosureClaimQuery) -> [LegacyDisclosureClaim] {
        return query.apply(store.list())
    }
}
