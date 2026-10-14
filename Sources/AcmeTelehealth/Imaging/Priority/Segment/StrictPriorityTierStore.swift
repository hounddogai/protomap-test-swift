import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps strict priority tiers by code.
    protocol StrictPriorityTierStore {
        func find(_ code: String) -> StrictPriorityTier?
        func save(_ item: StrictPriorityTier)
        func remove(_ code: String) -> Bool
        func list() -> [StrictPriorityTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictPriorityTierStore: StrictPriorityTierStore {
        var items: [String: StrictPriorityTier]
        var order: [String]

        init(items: [String: StrictPriorityTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictPriorityTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictPriorityTier) {
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

        func list() -> [StrictPriorityTier] {
            var out: [StrictPriorityTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictPriorityTierStore() -> any StrictPriorityTierStore {
        return MemoryStrictPriorityTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictPriorityTierStore: StrictPriorityTierStore {
        var inner: MemoryStrictPriorityTierStore
        var cache: TTLCache<StrictPriorityTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictPriorityTierStore, cache: TTLCache<StrictPriorityTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictPriorityTier? {
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

        func save(_ item: StrictPriorityTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictPriorityTier] {
            return inner.list()
        }
    }

    static func newCachedStrictPriorityTierStore(_ inner: MemoryStrictPriorityTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictPriorityTierStore {
        return CachedStrictPriorityTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict priority tiers. Empty fields match all.
    final class StrictPriorityTierQuery {
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

        func matches(_ item: StrictPriorityTier) -> Bool {
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

        func apply(_ items: [StrictPriorityTier]) -> [StrictPriorityTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictPriorityTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictPriorityTiers(_ store: any StrictPriorityTierStore, query: StrictPriorityTierQuery) -> [StrictPriorityTier] {
        return query.apply(store.list())
    }
}
