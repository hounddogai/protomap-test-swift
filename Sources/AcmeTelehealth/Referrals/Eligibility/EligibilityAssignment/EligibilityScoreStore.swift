import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility scores by code.
    protocol EligibilityScoreStore {
        func find(_ code: String) -> EligibilityScore?
        func save(_ item: EligibilityScore)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityScoreStore: EligibilityScoreStore {
        var items: [String: EligibilityScore]
        var order: [String]

        init(items: [String: EligibilityScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityScore) {
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

        func list() -> [EligibilityScore] {
            var out: [EligibilityScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityScoreStore() -> any EligibilityScoreStore {
        return MemoryEligibilityScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityScoreStore: EligibilityScoreStore {
        var inner: MemoryEligibilityScoreStore
        var cache: TTLCache<EligibilityScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityScoreStore, cache: TTLCache<EligibilityScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityScore? {
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

        func save(_ item: EligibilityScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityScore] {
            return inner.list()
        }
    }

    static func newCachedEligibilityScoreStore(_ inner: MemoryEligibilityScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityScoreStore {
        return CachedEligibilityScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility scores. Empty fields match all.
    final class EligibilityScoreQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [EligibilityScore]) -> [EligibilityScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityScores(_ store: any EligibilityScoreStore, query: EligibilityScoreQuery) -> [EligibilityScore] {
        return query.apply(store.list())
    }
}
