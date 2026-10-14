import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict result claims by code.
    protocol StrictResultClaimStore {
        func find(_ code: String) -> StrictResultClaim?
        func save(_ item: StrictResultClaim)
        func remove(_ code: String) -> Bool
        func list() -> [StrictResultClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictResultClaimStore: StrictResultClaimStore {
        var items: [String: StrictResultClaim]
        var order: [String]

        init(items: [String: StrictResultClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictResultClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictResultClaim) {
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

        func list() -> [StrictResultClaim] {
            var out: [StrictResultClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictResultClaimStore() -> any StrictResultClaimStore {
        return MemoryStrictResultClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictResultClaimStore: StrictResultClaimStore {
        var inner: MemoryStrictResultClaimStore
        var cache: TTLCache<StrictResultClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictResultClaimStore, cache: TTLCache<StrictResultClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictResultClaim? {
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

        func save(_ item: StrictResultClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictResultClaim] {
            return inner.list()
        }
    }

    static func newCachedStrictResultClaimStore(_ inner: MemoryStrictResultClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictResultClaimStore {
        return CachedStrictResultClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict result claims. Empty fields match all.
    final class StrictResultClaimQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictResultClaim) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictResultClaim]) -> [StrictResultClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictResultClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictResultClaims(_ store: any StrictResultClaimStore, query: StrictResultClaimQuery) -> [StrictResultClaim] {
        return query.apply(store.list())
    }
}
