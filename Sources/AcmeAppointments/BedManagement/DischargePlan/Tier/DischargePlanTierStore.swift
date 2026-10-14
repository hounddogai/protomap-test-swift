import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan tiers by code.
    protocol DischargePlanTierStore {
        func find(_ code: String) -> DischargePlanTier?
        func save(_ item: DischargePlanTier)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanTierStore: DischargePlanTierStore {
        var items: [String: DischargePlanTier]
        var order: [String]

        init(items: [String: DischargePlanTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanTier) {
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

        func list() -> [DischargePlanTier] {
            var out: [DischargePlanTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanTierStore() -> any DischargePlanTierStore {
        return MemoryDischargePlanTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanTierStore: DischargePlanTierStore {
        var inner: MemoryDischargePlanTierStore
        var cache: TTLCache<DischargePlanTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanTierStore, cache: TTLCache<DischargePlanTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanTier? {
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

        func save(_ item: DischargePlanTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanTier] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanTierStore(_ inner: MemoryDischargePlanTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanTierStore {
        return CachedDischargePlanTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan tiers. Empty fields match all.
    final class DischargePlanTierQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanTier) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanTier]) -> [DischargePlanTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanTiers(_ store: any DischargePlanTierStore, query: DischargePlanTierQuery) -> [DischargePlanTier] {
        return query.apply(store.list())
    }
}
