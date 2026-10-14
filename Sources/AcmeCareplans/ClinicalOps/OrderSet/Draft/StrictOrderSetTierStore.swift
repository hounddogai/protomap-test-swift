import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict order set tiers by code.
    protocol StrictOrderSetTierStore {
        func find(_ code: String) -> StrictOrderSetTier?
        func save(_ item: StrictOrderSetTier)
        func remove(_ code: String) -> Bool
        func list() -> [StrictOrderSetTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictOrderSetTierStore: StrictOrderSetTierStore {
        var items: [String: StrictOrderSetTier]
        var order: [String]

        init(items: [String: StrictOrderSetTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictOrderSetTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictOrderSetTier) {
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

        func list() -> [StrictOrderSetTier] {
            var out: [StrictOrderSetTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictOrderSetTierStore() -> any StrictOrderSetTierStore {
        return MemoryStrictOrderSetTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictOrderSetTierStore: StrictOrderSetTierStore {
        var inner: MemoryStrictOrderSetTierStore
        var cache: TTLCache<StrictOrderSetTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictOrderSetTierStore, cache: TTLCache<StrictOrderSetTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictOrderSetTier? {
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

        func save(_ item: StrictOrderSetTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictOrderSetTier] {
            return inner.list()
        }
    }

    static func newCachedStrictOrderSetTierStore(_ inner: MemoryStrictOrderSetTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictOrderSetTierStore {
        return CachedStrictOrderSetTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict order set tiers. Empty fields match all.
    final class StrictOrderSetTierQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictOrderSetTier) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictOrderSetTier]) -> [StrictOrderSetTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictOrderSetTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictOrderSetTiers(_ store: any StrictOrderSetTierStore, query: StrictOrderSetTierQuery) -> [StrictOrderSetTier] {
        return query.apply(store.list())
    }
}
