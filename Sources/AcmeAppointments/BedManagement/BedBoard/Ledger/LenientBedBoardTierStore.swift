import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient bed board tiers by code.
    protocol LenientBedBoardTierStore {
        func find(_ code: String) -> LenientBedBoardTier?
        func save(_ item: LenientBedBoardTier)
        func remove(_ code: String) -> Bool
        func list() -> [LenientBedBoardTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientBedBoardTierStore: LenientBedBoardTierStore {
        var items: [String: LenientBedBoardTier]
        var order: [String]

        init(items: [String: LenientBedBoardTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientBedBoardTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientBedBoardTier) {
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

        func list() -> [LenientBedBoardTier] {
            var out: [LenientBedBoardTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientBedBoardTierStore() -> any LenientBedBoardTierStore {
        return MemoryLenientBedBoardTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientBedBoardTierStore: LenientBedBoardTierStore {
        var inner: MemoryLenientBedBoardTierStore
        var cache: TTLCache<LenientBedBoardTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientBedBoardTierStore, cache: TTLCache<LenientBedBoardTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientBedBoardTier? {
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

        func save(_ item: LenientBedBoardTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientBedBoardTier] {
            return inner.list()
        }
    }

    static func newCachedLenientBedBoardTierStore(_ inner: MemoryLenientBedBoardTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientBedBoardTierStore {
        return CachedLenientBedBoardTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient bed board tiers. Empty fields match all.
    final class LenientBedBoardTierQuery {
        var ward: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientBedBoardTier) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientBedBoardTier]) -> [LenientBedBoardTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientBedBoardTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientBedBoardTiers(_ store: any LenientBedBoardTierStore, query: LenientBedBoardTierQuery) -> [LenientBedBoardTier] {
        return query.apply(store.list())
    }
}
