import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual statement tiers by code.
    protocol ManualStatementTierStore {
        func find(_ code: String) -> ManualStatementTier?
        func save(_ item: ManualStatementTier)
        func remove(_ code: String) -> Bool
        func list() -> [ManualStatementTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualStatementTierStore: ManualStatementTierStore {
        var items: [String: ManualStatementTier]
        var order: [String]

        init(items: [String: ManualStatementTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualStatementTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualStatementTier) {
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

        func list() -> [ManualStatementTier] {
            var out: [ManualStatementTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualStatementTierStore() -> any ManualStatementTierStore {
        return MemoryManualStatementTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualStatementTierStore: ManualStatementTierStore {
        var inner: MemoryManualStatementTierStore
        var cache: TTLCache<ManualStatementTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualStatementTierStore, cache: TTLCache<ManualStatementTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualStatementTier? {
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

        func save(_ item: ManualStatementTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualStatementTier] {
            return inner.list()
        }
    }

    static func newCachedManualStatementTierStore(_ inner: MemoryManualStatementTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualStatementTierStore {
        return CachedManualStatementTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual statement tiers. Empty fields match all.
    final class ManualStatementTierQuery {
        var country: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualStatementTier) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualStatementTier]) -> [ManualStatementTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualStatementTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualStatementTiers(_ store: any ManualStatementTierStore, query: ManualStatementTierQuery) -> [ManualStatementTier] {
        return query.apply(store.list())
    }
}
