import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result claims by code.
    protocol ResultClaimStore {
        func find(_ code: String) -> ResultClaim?
        func save(_ item: ResultClaim)
        func remove(_ code: String) -> Bool
        func list() -> [ResultClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultClaimStore: ResultClaimStore {
        var items: [String: ResultClaim]
        var order: [String]

        init(items: [String: ResultClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultClaim) {
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

        func list() -> [ResultClaim] {
            var out: [ResultClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultClaimStore() -> any ResultClaimStore {
        return MemoryResultClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultClaimStore: ResultClaimStore {
        var inner: MemoryResultClaimStore
        var cache: TTLCache<ResultClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultClaimStore, cache: TTLCache<ResultClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultClaim? {
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

        func save(_ item: ResultClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultClaim] {
            return inner.list()
        }
    }

    static func newCachedResultClaimStore(_ inner: MemoryResultClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultClaimStore {
        return CachedResultClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result claims. Empty fields match all.
    final class ResultClaimQuery {
        var ward: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultClaim) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultClaim]) -> [ResultClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultClaims(_ store: any ResultClaimStore, query: ResultClaimQuery) -> [ResultClaim] {
        return query.apply(store.list())
    }
}
