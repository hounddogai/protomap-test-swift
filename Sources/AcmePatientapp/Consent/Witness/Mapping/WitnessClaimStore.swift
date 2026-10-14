import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness claims by code.
    protocol WitnessClaimStore {
        func find(_ code: String) -> WitnessClaim?
        func save(_ item: WitnessClaim)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessClaimStore: WitnessClaimStore {
        var items: [String: WitnessClaim]
        var order: [String]

        init(items: [String: WitnessClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessClaim) {
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

        func list() -> [WitnessClaim] {
            var out: [WitnessClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessClaimStore() -> any WitnessClaimStore {
        return MemoryWitnessClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessClaimStore: WitnessClaimStore {
        var inner: MemoryWitnessClaimStore
        var cache: TTLCache<WitnessClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessClaimStore, cache: TTLCache<WitnessClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessClaim? {
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

        func save(_ item: WitnessClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessClaim] {
            return inner.list()
        }
    }

    static func newCachedWitnessClaimStore(_ inner: MemoryWitnessClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessClaimStore {
        return CachedWitnessClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness claims. Empty fields match all.
    final class WitnessClaimQuery {
        var facility: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCost: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessClaim) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [WitnessClaim]) -> [WitnessClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessClaims(_ store: any WitnessClaimStore, query: WitnessClaimQuery) -> [WitnessClaim] {
        return query.apply(store.list())
    }
}
