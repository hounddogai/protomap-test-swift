import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board tiers by code.
    protocol BedBoardTierStore {
        func find(_ code: String) -> BedBoardTier?
        func save(_ item: BedBoardTier)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardTierStore: BedBoardTierStore {
        var items: [String: BedBoardTier]
        var order: [String]

        init(items: [String: BedBoardTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardTier) {
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

        func list() -> [BedBoardTier] {
            var out: [BedBoardTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardTierStore() -> any BedBoardTierStore {
        return MemoryBedBoardTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardTierStore: BedBoardTierStore {
        var inner: MemoryBedBoardTierStore
        var cache: TTLCache<BedBoardTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardTierStore, cache: TTLCache<BedBoardTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardTier? {
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

        func save(_ item: BedBoardTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardTier] {
            return inner.list()
        }
    }

    static func newCachedBedBoardTierStore(_ inner: MemoryBedBoardTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardTierStore {
        return CachedBedBoardTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board tiers. Empty fields match all.
    final class BedBoardTierQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardTier) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [BedBoardTier]) -> [BedBoardTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardTiers(_ store: any BedBoardTierStore, query: BedBoardTierQuery) -> [BedBoardTier] {
        return query.apply(store.list())
    }
}
