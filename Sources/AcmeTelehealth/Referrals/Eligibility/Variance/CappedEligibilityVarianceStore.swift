import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped eligibility variances by code.
    protocol CappedEligibilityVarianceStore {
        func find(_ code: String) -> CappedEligibilityVariance?
        func save(_ item: CappedEligibilityVariance)
        func remove(_ code: String) -> Bool
        func list() -> [CappedEligibilityVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedEligibilityVarianceStore: CappedEligibilityVarianceStore {
        var items: [String: CappedEligibilityVariance]
        var order: [String]

        init(items: [String: CappedEligibilityVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedEligibilityVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedEligibilityVariance) {
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

        func list() -> [CappedEligibilityVariance] {
            var out: [CappedEligibilityVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedEligibilityVarianceStore() -> any CappedEligibilityVarianceStore {
        return MemoryCappedEligibilityVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedEligibilityVarianceStore: CappedEligibilityVarianceStore {
        var inner: MemoryCappedEligibilityVarianceStore
        var cache: TTLCache<CappedEligibilityVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedEligibilityVarianceStore, cache: TTLCache<CappedEligibilityVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedEligibilityVariance? {
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

        func save(_ item: CappedEligibilityVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedEligibilityVariance] {
            return inner.list()
        }
    }

    static func newCachedCappedEligibilityVarianceStore(_ inner: MemoryCappedEligibilityVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedEligibilityVarianceStore {
        return CachedCappedEligibilityVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped eligibility variances. Empty fields match all.
    final class CappedEligibilityVarianceQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedEligibilityVariance) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [CappedEligibilityVariance]) -> [CappedEligibilityVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedEligibilityVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedEligibilityVariances(_ store: any CappedEligibilityVarianceStore, query: CappedEligibilityVarianceQuery) -> [CappedEligibilityVariance] {
        return query.apply(store.list())
    }
}
