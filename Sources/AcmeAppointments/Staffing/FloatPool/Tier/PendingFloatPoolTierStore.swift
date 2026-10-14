import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending float pool tiers by code.
    protocol PendingFloatPoolTierStore {
        func find(_ code: String) -> PendingFloatPoolTier?
        func save(_ item: PendingFloatPoolTier)
        func remove(_ code: String) -> Bool
        func list() -> [PendingFloatPoolTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingFloatPoolTierStore: PendingFloatPoolTierStore {
        var items: [String: PendingFloatPoolTier]
        var order: [String]

        init(items: [String: PendingFloatPoolTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingFloatPoolTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingFloatPoolTier) {
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

        func list() -> [PendingFloatPoolTier] {
            var out: [PendingFloatPoolTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingFloatPoolTierStore() -> any PendingFloatPoolTierStore {
        return MemoryPendingFloatPoolTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingFloatPoolTierStore: PendingFloatPoolTierStore {
        var inner: MemoryPendingFloatPoolTierStore
        var cache: TTLCache<PendingFloatPoolTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingFloatPoolTierStore, cache: TTLCache<PendingFloatPoolTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingFloatPoolTier? {
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

        func save(_ item: PendingFloatPoolTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingFloatPoolTier] {
            return inner.list()
        }
    }

    static func newCachedPendingFloatPoolTierStore(_ inner: MemoryPendingFloatPoolTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingFloatPoolTierStore {
        return CachedPendingFloatPoolTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending float pool tiers. Empty fields match all.
    final class PendingFloatPoolTierQuery {
        var source: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRetries: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingFloatPoolTier) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingFloatPoolTier]) -> [PendingFloatPoolTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingFloatPoolTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingFloatPoolTiers(_ store: any PendingFloatPoolTierStore, query: PendingFloatPoolTierQuery) -> [PendingFloatPoolTier] {
        return query.apply(store.list())
    }
}
