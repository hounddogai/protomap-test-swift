import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global rounding claims by code.
    protocol GlobalRoundingClaimStore {
        func find(_ code: String) -> GlobalRoundingClaim?
        func save(_ item: GlobalRoundingClaim)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalRoundingClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalRoundingClaimStore: GlobalRoundingClaimStore {
        var items: [String: GlobalRoundingClaim]
        var order: [String]

        init(items: [String: GlobalRoundingClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalRoundingClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalRoundingClaim) {
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

        func list() -> [GlobalRoundingClaim] {
            var out: [GlobalRoundingClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalRoundingClaimStore() -> any GlobalRoundingClaimStore {
        return MemoryGlobalRoundingClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalRoundingClaimStore: GlobalRoundingClaimStore {
        var inner: MemoryGlobalRoundingClaimStore
        var cache: TTLCache<GlobalRoundingClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalRoundingClaimStore, cache: TTLCache<GlobalRoundingClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalRoundingClaim? {
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

        func save(_ item: GlobalRoundingClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalRoundingClaim] {
            return inner.list()
        }
    }

    static func newCachedGlobalRoundingClaimStore(_ inner: MemoryGlobalRoundingClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalRoundingClaimStore {
        return CachedGlobalRoundingClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global rounding claims. Empty fields match all.
    final class GlobalRoundingClaimQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalRoundingClaim) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalRoundingClaim]) -> [GlobalRoundingClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalRoundingClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalRoundingClaims(_ store: any GlobalRoundingClaimStore, query: GlobalRoundingClaimQuery) -> [GlobalRoundingClaim] {
        return query.apply(store.list())
    }
}
