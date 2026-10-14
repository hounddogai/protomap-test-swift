import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global eligibility variances by code.
    protocol GlobalEligibilityVarianceStore {
        func find(_ code: String) -> GlobalEligibilityVariance?
        func save(_ item: GlobalEligibilityVariance)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalEligibilityVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalEligibilityVarianceStore: GlobalEligibilityVarianceStore {
        var items: [String: GlobalEligibilityVariance]
        var order: [String]

        init(items: [String: GlobalEligibilityVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalEligibilityVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalEligibilityVariance) {
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

        func list() -> [GlobalEligibilityVariance] {
            var out: [GlobalEligibilityVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalEligibilityVarianceStore() -> any GlobalEligibilityVarianceStore {
        return MemoryGlobalEligibilityVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalEligibilityVarianceStore: GlobalEligibilityVarianceStore {
        var inner: MemoryGlobalEligibilityVarianceStore
        var cache: TTLCache<GlobalEligibilityVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalEligibilityVarianceStore, cache: TTLCache<GlobalEligibilityVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalEligibilityVariance? {
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

        func save(_ item: GlobalEligibilityVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalEligibilityVariance] {
            return inner.list()
        }
    }

    static func newCachedGlobalEligibilityVarianceStore(_ inner: MemoryGlobalEligibilityVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalEligibilityVarianceStore {
        return CachedGlobalEligibilityVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global eligibility variances. Empty fields match all.
    final class GlobalEligibilityVarianceQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalEligibilityVariance) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalEligibilityVariance]) -> [GlobalEligibilityVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalEligibilityVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalEligibilityVariances(_ store: any GlobalEligibilityVarianceStore, query: GlobalEligibilityVarianceQuery) -> [GlobalEligibilityVariance] {
        return query.apply(store.list())
    }
}
