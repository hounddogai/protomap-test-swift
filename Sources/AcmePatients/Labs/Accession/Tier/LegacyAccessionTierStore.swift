import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy accession tiers by code.
    protocol LegacyAccessionTierStore {
        func find(_ code: String) -> LegacyAccessionTier?
        func save(_ item: LegacyAccessionTier)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAccessionTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAccessionTierStore: LegacyAccessionTierStore {
        var items: [String: LegacyAccessionTier]
        var order: [String]

        init(items: [String: LegacyAccessionTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAccessionTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAccessionTier) {
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

        func list() -> [LegacyAccessionTier] {
            var out: [LegacyAccessionTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAccessionTierStore() -> any LegacyAccessionTierStore {
        return MemoryLegacyAccessionTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAccessionTierStore: LegacyAccessionTierStore {
        var inner: MemoryLegacyAccessionTierStore
        var cache: TTLCache<LegacyAccessionTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAccessionTierStore, cache: TTLCache<LegacyAccessionTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAccessionTier? {
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

        func save(_ item: LegacyAccessionTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAccessionTier] {
            return inner.list()
        }
    }

    static func newCachedLegacyAccessionTierStore(_ inner: MemoryLegacyAccessionTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAccessionTierStore {
        return CachedLegacyAccessionTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy accession tiers. Empty fields match all.
    final class LegacyAccessionTierQuery {
        var segment: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAccessionTier) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [LegacyAccessionTier]) -> [LegacyAccessionTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAccessionTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAccessionTiers(_ store: any LegacyAccessionTierStore, query: LegacyAccessionTierQuery) -> [LegacyAccessionTier] {
        return query.apply(store.list())
    }
}
