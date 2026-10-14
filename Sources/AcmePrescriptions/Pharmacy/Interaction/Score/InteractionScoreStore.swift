import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction scores by code.
    protocol InteractionScoreStore {
        func find(_ code: String) -> InteractionScore?
        func save(_ item: InteractionScore)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionScoreStore: InteractionScoreStore {
        var items: [String: InteractionScore]
        var order: [String]

        init(items: [String: InteractionScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionScore) {
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

        func list() -> [InteractionScore] {
            var out: [InteractionScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionScoreStore() -> any InteractionScoreStore {
        return MemoryInteractionScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionScoreStore: InteractionScoreStore {
        var inner: MemoryInteractionScoreStore
        var cache: TTLCache<InteractionScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionScoreStore, cache: TTLCache<InteractionScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionScore? {
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

        func save(_ item: InteractionScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionScore] {
            return inner.list()
        }
    }

    static func newCachedInteractionScoreStore(_ inner: MemoryInteractionScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionScoreStore {
        return CachedInteractionScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction scores. Empty fields match all.
    final class InteractionScoreQuery {
        var source: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRate: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionScore) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionScore]) -> [InteractionScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionScores(_ store: any InteractionScoreStore, query: InteractionScoreQuery) -> [InteractionScore] {
        return query.apply(store.list())
    }
}
