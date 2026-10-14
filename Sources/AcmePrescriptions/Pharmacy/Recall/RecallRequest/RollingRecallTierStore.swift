import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps rolling recall tiers by code.
    protocol RollingRecallTierStore {
        func find(_ code: String) -> RollingRecallTier?
        func save(_ item: RollingRecallTier)
        func remove(_ code: String) -> Bool
        func list() -> [RollingRecallTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingRecallTierStore: RollingRecallTierStore {
        var items: [String: RollingRecallTier]
        var order: [String]

        init(items: [String: RollingRecallTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingRecallTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingRecallTier) {
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

        func list() -> [RollingRecallTier] {
            var out: [RollingRecallTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingRecallTierStore() -> any RollingRecallTierStore {
        return MemoryRollingRecallTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingRecallTierStore: RollingRecallTierStore {
        var inner: MemoryRollingRecallTierStore
        var cache: TTLCache<RollingRecallTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingRecallTierStore, cache: TTLCache<RollingRecallTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingRecallTier? {
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

        func save(_ item: RollingRecallTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingRecallTier] {
            return inner.list()
        }
    }

    static func newCachedRollingRecallTierStore(_ inner: MemoryRollingRecallTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingRecallTierStore {
        return CachedRollingRecallTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling recall tiers. Empty fields match all.
    final class RollingRecallTierQuery {
        var source: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRatio: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingRecallTier) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingRecallTier]) -> [RollingRecallTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingRecallTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingRecallTiers(_ store: any RollingRecallTierStore, query: RollingRecallTierQuery) -> [RollingRecallTier] {
        return query.apply(store.list())
    }
}
