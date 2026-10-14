import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback eligibility scores by code.
    protocol FallbackEligibilityScoreStore {
        func find(_ code: String) -> FallbackEligibilityScore?
        func save(_ item: FallbackEligibilityScore)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackEligibilityScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackEligibilityScoreStore: FallbackEligibilityScoreStore {
        var items: [String: FallbackEligibilityScore]
        var order: [String]

        init(items: [String: FallbackEligibilityScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackEligibilityScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackEligibilityScore) {
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

        func list() -> [FallbackEligibilityScore] {
            var out: [FallbackEligibilityScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackEligibilityScoreStore() -> any FallbackEligibilityScoreStore {
        return MemoryFallbackEligibilityScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackEligibilityScoreStore: FallbackEligibilityScoreStore {
        var inner: MemoryFallbackEligibilityScoreStore
        var cache: TTLCache<FallbackEligibilityScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackEligibilityScoreStore, cache: TTLCache<FallbackEligibilityScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackEligibilityScore? {
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

        func save(_ item: FallbackEligibilityScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackEligibilityScore] {
            return inner.list()
        }
    }

    static func newCachedFallbackEligibilityScoreStore(_ inner: MemoryFallbackEligibilityScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackEligibilityScoreStore {
        return CachedFallbackEligibilityScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback eligibility scores. Empty fields match all.
    final class FallbackEligibilityScoreQuery {
        var category: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRefills: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackEligibilityScore) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackEligibilityScore]) -> [FallbackEligibilityScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackEligibilityScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackEligibilityScores(_ store: any FallbackEligibilityScoreStore, query: FallbackEligibilityScoreQuery) -> [FallbackEligibilityScore] {
        return query.apply(store.list())
    }
}
