import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding claims by code.
    protocol RoundingClaimStore {
        func find(_ code: String) -> RoundingClaim?
        func save(_ item: RoundingClaim)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingClaimStore: RoundingClaimStore {
        var items: [String: RoundingClaim]
        var order: [String]

        init(items: [String: RoundingClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingClaim) {
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

        func list() -> [RoundingClaim] {
            var out: [RoundingClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingClaimStore() -> any RoundingClaimStore {
        return MemoryRoundingClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingClaimStore: RoundingClaimStore {
        var inner: MemoryRoundingClaimStore
        var cache: TTLCache<RoundingClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingClaimStore, cache: TTLCache<RoundingClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingClaim? {
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

        func save(_ item: RoundingClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingClaim] {
            return inner.list()
        }
    }

    static func newCachedRoundingClaimStore(_ inner: MemoryRoundingClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingClaimStore {
        return CachedRoundingClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding claims. Empty fields match all.
    final class RoundingClaimQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingClaim) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingClaim]) -> [RoundingClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingClaims(_ store: any RoundingClaimStore, query: RoundingClaimQuery) -> [RoundingClaim] {
        return query.apply(store.list())
    }
}
