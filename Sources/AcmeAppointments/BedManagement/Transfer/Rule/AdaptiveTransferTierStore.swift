import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive transfer tiers by code.
    protocol AdaptiveTransferTierStore {
        func find(_ code: String) -> AdaptiveTransferTier?
        func save(_ item: AdaptiveTransferTier)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveTransferTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveTransferTierStore: AdaptiveTransferTierStore {
        var items: [String: AdaptiveTransferTier]
        var order: [String]

        init(items: [String: AdaptiveTransferTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveTransferTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveTransferTier) {
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

        func list() -> [AdaptiveTransferTier] {
            var out: [AdaptiveTransferTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveTransferTierStore() -> any AdaptiveTransferTierStore {
        return MemoryAdaptiveTransferTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveTransferTierStore: AdaptiveTransferTierStore {
        var inner: MemoryAdaptiveTransferTierStore
        var cache: TTLCache<AdaptiveTransferTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveTransferTierStore, cache: TTLCache<AdaptiveTransferTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveTransferTier? {
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

        func save(_ item: AdaptiveTransferTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveTransferTier] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveTransferTierStore(_ inner: MemoryAdaptiveTransferTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveTransferTierStore {
        return CachedAdaptiveTransferTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive transfer tiers. Empty fields match all.
    final class AdaptiveTransferTierQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveTransferTier) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveTransferTier]) -> [AdaptiveTransferTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveTransferTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveTransferTiers(_ store: any AdaptiveTransferTierStore, query: AdaptiveTransferTierQuery) -> [AdaptiveTransferTier] {
        return query.apply(store.list())
    }
}
