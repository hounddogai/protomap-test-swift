import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional alert tiers by code.
    protocol RegionalAlertTierStore {
        func find(_ code: String) -> RegionalAlertTier?
        func save(_ item: RegionalAlertTier)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalAlertTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalAlertTierStore: RegionalAlertTierStore {
        var items: [String: RegionalAlertTier]
        var order: [String]

        init(items: [String: RegionalAlertTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalAlertTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalAlertTier) {
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

        func list() -> [RegionalAlertTier] {
            var out: [RegionalAlertTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalAlertTierStore() -> any RegionalAlertTierStore {
        return MemoryRegionalAlertTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalAlertTierStore: RegionalAlertTierStore {
        var inner: MemoryRegionalAlertTierStore
        var cache: TTLCache<RegionalAlertTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalAlertTierStore, cache: TTLCache<RegionalAlertTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalAlertTier? {
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

        func save(_ item: RegionalAlertTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalAlertTier] {
            return inner.list()
        }
    }

    static func newCachedRegionalAlertTierStore(_ inner: MemoryRegionalAlertTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalAlertTierStore {
        return CachedRegionalAlertTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional alert tiers. Empty fields match all.
    final class RegionalAlertTierQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalAlertTier) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalAlertTier]) -> [RegionalAlertTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalAlertTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalAlertTiers(_ store: any RegionalAlertTierStore, query: RegionalAlertTierQuery) -> [RegionalAlertTier] {
        return query.apply(store.list())
    }
}
