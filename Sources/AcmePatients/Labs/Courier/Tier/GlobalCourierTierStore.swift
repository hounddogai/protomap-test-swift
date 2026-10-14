import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global courier tiers by code.
    protocol GlobalCourierTierStore {
        func find(_ code: String) -> GlobalCourierTier?
        func save(_ item: GlobalCourierTier)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCourierTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCourierTierStore: GlobalCourierTierStore {
        var items: [String: GlobalCourierTier]
        var order: [String]

        init(items: [String: GlobalCourierTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCourierTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCourierTier) {
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

        func list() -> [GlobalCourierTier] {
            var out: [GlobalCourierTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCourierTierStore() -> any GlobalCourierTierStore {
        return MemoryGlobalCourierTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCourierTierStore: GlobalCourierTierStore {
        var inner: MemoryGlobalCourierTierStore
        var cache: TTLCache<GlobalCourierTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCourierTierStore, cache: TTLCache<GlobalCourierTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCourierTier? {
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

        func save(_ item: GlobalCourierTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCourierTier] {
            return inner.list()
        }
    }

    static func newCachedGlobalCourierTierStore(_ inner: MemoryGlobalCourierTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCourierTierStore {
        return CachedGlobalCourierTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global courier tiers. Empty fields match all.
    final class GlobalCourierTierQuery {
        var channel: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minScore: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCourierTier) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalCourierTier]) -> [GlobalCourierTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCourierTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCourierTiers(_ store: any GlobalCourierTierStore, query: GlobalCourierTierQuery) -> [GlobalCourierTier] {
        return query.apply(store.list())
    }
}
