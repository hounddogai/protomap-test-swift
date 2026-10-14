import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual denial tiers by code.
    protocol ManualDenialTierStore {
        func find(_ code: String) -> ManualDenialTier?
        func save(_ item: ManualDenialTier)
        func remove(_ code: String) -> Bool
        func list() -> [ManualDenialTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualDenialTierStore: ManualDenialTierStore {
        var items: [String: ManualDenialTier]
        var order: [String]

        init(items: [String: ManualDenialTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualDenialTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualDenialTier) {
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

        func list() -> [ManualDenialTier] {
            var out: [ManualDenialTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualDenialTierStore() -> any ManualDenialTierStore {
        return MemoryManualDenialTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualDenialTierStore: ManualDenialTierStore {
        var inner: MemoryManualDenialTierStore
        var cache: TTLCache<ManualDenialTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualDenialTierStore, cache: TTLCache<ManualDenialTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualDenialTier? {
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

        func save(_ item: ManualDenialTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualDenialTier] {
            return inner.list()
        }
    }

    static func newCachedManualDenialTierStore(_ inner: MemoryManualDenialTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualDenialTierStore {
        return CachedManualDenialTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual denial tiers. Empty fields match all.
    final class ManualDenialTierQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualDenialTier) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ManualDenialTier]) -> [ManualDenialTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualDenialTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualDenialTiers(_ store: any ManualDenialTierStore, query: ManualDenialTierQuery) -> [ManualDenialTier] {
        return query.apply(store.list())
    }
}
