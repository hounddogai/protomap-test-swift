import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility digests by code.
    protocol EligibilityDigestStore {
        func find(_ code: String) -> EligibilityDigest?
        func save(_ item: EligibilityDigest)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityDigestStore: EligibilityDigestStore {
        var items: [String: EligibilityDigest]
        var order: [String]

        init(items: [String: EligibilityDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityDigest) {
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

        func list() -> [EligibilityDigest] {
            var out: [EligibilityDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityDigestStore() -> any EligibilityDigestStore {
        return MemoryEligibilityDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityDigestStore: EligibilityDigestStore {
        var inner: MemoryEligibilityDigestStore
        var cache: TTLCache<EligibilityDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityDigestStore, cache: TTLCache<EligibilityDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityDigest? {
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

        func save(_ item: EligibilityDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityDigest] {
            return inner.list()
        }
    }

    static func newCachedEligibilityDigestStore(_ inner: MemoryEligibilityDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityDigestStore {
        return CachedEligibilityDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility digests. Empty fields match all.
    final class EligibilityDigestQuery {
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

        func matches(_ item: EligibilityDigest) -> Bool {
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

        func apply(_ items: [EligibilityDigest]) -> [EligibilityDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityDigests(_ store: any EligibilityDigestStore, query: EligibilityDigestQuery) -> [EligibilityDigest] {
        return query.apply(store.list())
    }
}
