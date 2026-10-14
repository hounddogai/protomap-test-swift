import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility rollups by code.
    protocol EligibilityRollupStore {
        func find(_ code: String) -> EligibilityRollup?
        func save(_ item: EligibilityRollup)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityRollupStore: EligibilityRollupStore {
        var items: [String: EligibilityRollup]
        var order: [String]

        init(items: [String: EligibilityRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityRollup) {
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

        func list() -> [EligibilityRollup] {
            var out: [EligibilityRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityRollupStore() -> any EligibilityRollupStore {
        return MemoryEligibilityRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityRollupStore: EligibilityRollupStore {
        var inner: MemoryEligibilityRollupStore
        var cache: TTLCache<EligibilityRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityRollupStore, cache: TTLCache<EligibilityRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityRollup? {
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

        func save(_ item: EligibilityRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityRollup] {
            return inner.list()
        }
    }

    static func newCachedEligibilityRollupStore(_ inner: MemoryEligibilityRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityRollupStore {
        return CachedEligibilityRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility rollups. Empty fields match all.
    final class EligibilityRollupQuery {
        var category: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityRollup) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityRollup]) -> [EligibilityRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityRollups(_ store: any EligibilityRollupStore, query: EligibilityRollupQuery) -> [EligibilityRollup] {
        return query.apply(store.list())
    }
}
