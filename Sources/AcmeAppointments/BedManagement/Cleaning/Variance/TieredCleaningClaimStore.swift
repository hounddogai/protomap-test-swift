import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps tiered cleaning claims by code.
    protocol TieredCleaningClaimStore {
        func find(_ code: String) -> TieredCleaningClaim?
        func save(_ item: TieredCleaningClaim)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCleaningClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCleaningClaimStore: TieredCleaningClaimStore {
        var items: [String: TieredCleaningClaim]
        var order: [String]

        init(items: [String: TieredCleaningClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCleaningClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCleaningClaim) {
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

        func list() -> [TieredCleaningClaim] {
            var out: [TieredCleaningClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCleaningClaimStore() -> any TieredCleaningClaimStore {
        return MemoryTieredCleaningClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCleaningClaimStore: TieredCleaningClaimStore {
        var inner: MemoryTieredCleaningClaimStore
        var cache: TTLCache<TieredCleaningClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCleaningClaimStore, cache: TTLCache<TieredCleaningClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCleaningClaim? {
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

        func save(_ item: TieredCleaningClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCleaningClaim] {
            return inner.list()
        }
    }

    static func newCachedTieredCleaningClaimStore(_ inner: MemoryTieredCleaningClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCleaningClaimStore {
        return CachedTieredCleaningClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered cleaning claims. Empty fields match all.
    final class TieredCleaningClaimQuery {
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

        func matches(_ item: TieredCleaningClaim) -> Bool {
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

        func apply(_ items: [TieredCleaningClaim]) -> [TieredCleaningClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCleaningClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCleaningClaims(_ store: any TieredCleaningClaimStore, query: TieredCleaningClaimQuery) -> [TieredCleaningClaim] {
        return query.apply(store.list())
    }
}
