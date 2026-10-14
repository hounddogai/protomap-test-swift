import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding tiers by code.
    protocol RoundingTierStore {
        func find(_ code: String) -> RoundingTier?
        func save(_ item: RoundingTier)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingTierStore: RoundingTierStore {
        var items: [String: RoundingTier]
        var order: [String]

        init(items: [String: RoundingTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingTier) {
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

        func list() -> [RoundingTier] {
            var out: [RoundingTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingTierStore() -> any RoundingTierStore {
        return MemoryRoundingTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingTierStore: RoundingTierStore {
        var inner: MemoryRoundingTierStore
        var cache: TTLCache<RoundingTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingTierStore, cache: TTLCache<RoundingTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingTier? {
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

        func save(_ item: RoundingTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingTier] {
            return inner.list()
        }
    }

    static func newCachedRoundingTierStore(_ inner: MemoryRoundingTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingTierStore {
        return CachedRoundingTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding tiers. Empty fields match all.
    final class RoundingTierQuery {
        var source: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingTier) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingTier]) -> [RoundingTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingTiers(_ store: any RoundingTierStore, query: RoundingTierQuery) -> [RoundingTier] {
        return query.apply(store.list())
    }
}
