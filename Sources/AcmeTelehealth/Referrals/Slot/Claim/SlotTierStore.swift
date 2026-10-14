import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot tiers by code.
    protocol SlotTierStore {
        func find(_ code: String) -> SlotTier?
        func save(_ item: SlotTier)
        func remove(_ code: String) -> Bool
        func list() -> [SlotTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotTierStore: SlotTierStore {
        var items: [String: SlotTier]
        var order: [String]

        init(items: [String: SlotTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotTier) {
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

        func list() -> [SlotTier] {
            var out: [SlotTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotTierStore() -> any SlotTierStore {
        return MemorySlotTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotTierStore: SlotTierStore {
        var inner: MemorySlotTierStore
        var cache: TTLCache<SlotTier>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotTierStore, cache: TTLCache<SlotTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotTier? {
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

        func save(_ item: SlotTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotTier] {
            return inner.list()
        }
    }

    static func newCachedSlotTierStore(_ inner: MemorySlotTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotTierStore {
        return CachedSlotTierStore(inner: inner, cache: newTTLCache(128, ttl: ttl, clock: clock), hits: 0, misses: 0)
    }

    /// Selects slot tiers. Empty fields match all.
    final class SlotTierQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotTier) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [SlotTier]) -> [SlotTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotTiers(_ store: any SlotTierStore, query: SlotTierQuery) -> [SlotTier] {
        return query.apply(store.list())
    }
}
