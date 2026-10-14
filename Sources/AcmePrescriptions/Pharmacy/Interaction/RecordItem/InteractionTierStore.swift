import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction tiers by code.
    protocol InteractionTierStore {
        func find(_ code: String) -> InteractionTier?
        func save(_ item: InteractionTier)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionTierStore: InteractionTierStore {
        var items: [String: InteractionTier]
        var order: [String]

        init(items: [String: InteractionTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionTier) {
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

        func list() -> [InteractionTier] {
            var out: [InteractionTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionTierStore() -> any InteractionTierStore {
        return MemoryInteractionTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionTierStore: InteractionTierStore {
        var inner: MemoryInteractionTierStore
        var cache: TTLCache<InteractionTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionTierStore, cache: TTLCache<InteractionTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionTier? {
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

        func save(_ item: InteractionTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionTier] {
            return inner.list()
        }
    }

    static func newCachedInteractionTierStore(_ inner: MemoryInteractionTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionTierStore {
        return CachedInteractionTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction tiers. Empty fields match all.
    final class InteractionTierQuery {
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

        func matches(_ item: InteractionTier) -> Bool {
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

        func apply(_ items: [InteractionTier]) -> [InteractionTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionTiers(_ store: any InteractionTierStore, query: InteractionTierQuery) -> [InteractionTier] {
        return query.apply(store.list())
    }
}
