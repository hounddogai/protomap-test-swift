import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps strict goal tiers by code.
    protocol StrictGoalTierStore {
        func find(_ code: String) -> StrictGoalTier?
        func save(_ item: StrictGoalTier)
        func remove(_ code: String) -> Bool
        func list() -> [StrictGoalTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictGoalTierStore: StrictGoalTierStore {
        var items: [String: StrictGoalTier]
        var order: [String]

        init(items: [String: StrictGoalTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictGoalTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictGoalTier) {
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

        func list() -> [StrictGoalTier] {
            var out: [StrictGoalTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictGoalTierStore() -> any StrictGoalTierStore {
        return MemoryStrictGoalTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictGoalTierStore: StrictGoalTierStore {
        var inner: MemoryStrictGoalTierStore
        var cache: TTLCache<StrictGoalTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictGoalTierStore, cache: TTLCache<StrictGoalTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictGoalTier? {
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

        func save(_ item: StrictGoalTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictGoalTier] {
            return inner.list()
        }
    }

    static func newCachedStrictGoalTierStore(_ inner: MemoryStrictGoalTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictGoalTierStore {
        return CachedStrictGoalTierStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict goal tiers. Empty fields match all.
    final class StrictGoalTierQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictGoalTier) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictGoalTier]) -> [StrictGoalTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictGoalTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictGoalTiers(_ store: any StrictGoalTierStore, query: StrictGoalTierQuery) -> [StrictGoalTier] {
        return query.apply(store.list())
    }
}
