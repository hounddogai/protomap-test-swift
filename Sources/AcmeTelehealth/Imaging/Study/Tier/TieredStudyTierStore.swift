import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered study tiers by code.
    protocol TieredStudyTierStore {
        func find(_ code: String) -> TieredStudyTier?
        func save(_ item: TieredStudyTier)
        func remove(_ code: String) -> Bool
        func list() -> [TieredStudyTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredStudyTierStore: TieredStudyTierStore {
        var items: [String: TieredStudyTier]
        var order: [String]

        init(items: [String: TieredStudyTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredStudyTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredStudyTier) {
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

        func list() -> [TieredStudyTier] {
            var out: [TieredStudyTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredStudyTierStore() -> any TieredStudyTierStore {
        return MemoryTieredStudyTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredStudyTierStore: TieredStudyTierStore {
        var inner: MemoryTieredStudyTierStore
        var cache: TTLCache<TieredStudyTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredStudyTierStore, cache: TTLCache<TieredStudyTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredStudyTier? {
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

        func save(_ item: TieredStudyTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredStudyTier] {
            return inner.list()
        }
    }

    static func newCachedTieredStudyTierStore(_ inner: MemoryTieredStudyTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredStudyTierStore {
        return CachedTieredStudyTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered study tiers. Empty fields match all.
    final class TieredStudyTierQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredStudyTier) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [TieredStudyTier]) -> [TieredStudyTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredStudyTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredStudyTiers(_ store: any TieredStudyTierStore, query: TieredStudyTierQuery) -> [TieredStudyTier] {
        return query.apply(store.list())
    }
}
