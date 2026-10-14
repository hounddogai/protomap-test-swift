import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall tiers by code.
    protocol RecallTierStore {
        func find(_ code: String) -> RecallTier?
        func save(_ item: RecallTier)
        func remove(_ code: String) -> Bool
        func list() -> [RecallTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallTierStore: RecallTierStore {
        var items: [String: RecallTier]
        var order: [String]

        init(items: [String: RecallTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallTier) {
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

        func list() -> [RecallTier] {
            var out: [RecallTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallTierStore() -> any RecallTierStore {
        return MemoryRecallTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallTierStore: RecallTierStore {
        var inner: MemoryRecallTierStore
        var cache: TTLCache<RecallTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallTierStore, cache: TTLCache<RecallTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallTier? {
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

        func save(_ item: RecallTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallTier] {
            return inner.list()
        }
    }

    static func newCachedRecallTierStore(_ inner: MemoryRecallTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallTierStore {
        return CachedRecallTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall tiers. Empty fields match all.
    final class RecallTierQuery {
        var label: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallTier) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallTier]) -> [RecallTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallTiers(_ store: any RecallTierStore, query: RecallTierQuery) -> [RecallTier] {
        return query.apply(store.list())
    }
}
