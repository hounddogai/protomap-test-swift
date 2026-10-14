import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps capped shift tiers by code.
    protocol CappedShiftTierStore {
        func find(_ code: String) -> CappedShiftTier?
        func save(_ item: CappedShiftTier)
        func remove(_ code: String) -> Bool
        func list() -> [CappedShiftTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedShiftTierStore: CappedShiftTierStore {
        var items: [String: CappedShiftTier]
        var order: [String]

        init(items: [String: CappedShiftTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedShiftTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedShiftTier) {
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

        func list() -> [CappedShiftTier] {
            var out: [CappedShiftTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedShiftTierStore() -> any CappedShiftTierStore {
        return MemoryCappedShiftTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedShiftTierStore: CappedShiftTierStore {
        var inner: MemoryCappedShiftTierStore
        var cache: TTLCache<CappedShiftTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedShiftTierStore, cache: TTLCache<CappedShiftTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedShiftTier? {
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

        func save(_ item: CappedShiftTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedShiftTier] {
            return inner.list()
        }
    }

    static func newCachedCappedShiftTierStore(_ inner: MemoryCappedShiftTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedShiftTierStore {
        return CachedCappedShiftTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped shift tiers. Empty fields match all.
    final class CappedShiftTierQuery {
        var facility: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedShiftTier) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedShiftTier]) -> [CappedShiftTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedShiftTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedShiftTiers(_ store: any CappedShiftTierStore, query: CappedShiftTierQuery) -> [CappedShiftTier] {
        return query.apply(store.list())
    }
}
