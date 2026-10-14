import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps capped program claims by code.
    protocol CappedProgramClaimStore {
        func find(_ code: String) -> CappedProgramClaim?
        func save(_ item: CappedProgramClaim)
        func remove(_ code: String) -> Bool
        func list() -> [CappedProgramClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedProgramClaimStore: CappedProgramClaimStore {
        var items: [String: CappedProgramClaim]
        var order: [String]

        init(items: [String: CappedProgramClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedProgramClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedProgramClaim) {
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

        func list() -> [CappedProgramClaim] {
            var out: [CappedProgramClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedProgramClaimStore() -> any CappedProgramClaimStore {
        return MemoryCappedProgramClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedProgramClaimStore: CappedProgramClaimStore {
        var inner: MemoryCappedProgramClaimStore
        var cache: TTLCache<CappedProgramClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedProgramClaimStore, cache: TTLCache<CappedProgramClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedProgramClaim? {
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

        func save(_ item: CappedProgramClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedProgramClaim] {
            return inner.list()
        }
    }

    static func newCachedCappedProgramClaimStore(_ inner: MemoryCappedProgramClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedProgramClaimStore {
        return CachedCappedProgramClaimStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped program claims. Empty fields match all.
    final class CappedProgramClaimQuery {
        var region: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedProgramClaim) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedProgramClaim]) -> [CappedProgramClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedProgramClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedProgramClaims(_ store: any CappedProgramClaimStore, query: CappedProgramClaimQuery) -> [CappedProgramClaim] {
        return query.apply(store.list())
    }
}
