import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up scores by code.
    protocol FollowUpScoreStore {
        func find(_ code: String) -> FollowUpScore?
        func save(_ item: FollowUpScore)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpScoreStore: FollowUpScoreStore {
        var items: [String: FollowUpScore]
        var order: [String]

        init(items: [String: FollowUpScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpScore) {
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

        func list() -> [FollowUpScore] {
            var out: [FollowUpScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpScoreStore() -> any FollowUpScoreStore {
        return MemoryFollowUpScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpScoreStore: FollowUpScoreStore {
        var inner: MemoryFollowUpScoreStore
        var cache: TTLCache<FollowUpScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpScoreStore, cache: TTLCache<FollowUpScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpScore? {
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

        func save(_ item: FollowUpScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpScore] {
            return inner.list()
        }
    }

    static func newCachedFollowUpScoreStore(_ inner: MemoryFollowUpScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpScoreStore {
        return CachedFollowUpScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up scores. Empty fields match all.
    final class FollowUpScoreQuery {
        var country: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minAmount: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpScore) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpScore]) -> [FollowUpScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpScores(_ store: any FollowUpScoreStore, query: FollowUpScoreQuery) -> [FollowUpScore] {
        return query.apply(store.list())
    }
}
