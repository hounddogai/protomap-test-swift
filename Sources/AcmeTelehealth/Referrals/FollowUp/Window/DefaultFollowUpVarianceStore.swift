import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps default follow up variances by code.
    protocol DefaultFollowUpVarianceStore {
        func find(_ code: String) -> DefaultFollowUpVariance?
        func save(_ item: DefaultFollowUpVariance)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultFollowUpVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultFollowUpVarianceStore: DefaultFollowUpVarianceStore {
        var items: [String: DefaultFollowUpVariance]
        var order: [String]

        init(items: [String: DefaultFollowUpVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultFollowUpVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultFollowUpVariance) {
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

        func list() -> [DefaultFollowUpVariance] {
            var out: [DefaultFollowUpVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultFollowUpVarianceStore() -> any DefaultFollowUpVarianceStore {
        return MemoryDefaultFollowUpVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultFollowUpVarianceStore: DefaultFollowUpVarianceStore {
        var inner: MemoryDefaultFollowUpVarianceStore
        var cache: TTLCache<DefaultFollowUpVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultFollowUpVarianceStore, cache: TTLCache<DefaultFollowUpVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultFollowUpVariance? {
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

        func save(_ item: DefaultFollowUpVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultFollowUpVariance] {
            return inner.list()
        }
    }

    static func newCachedDefaultFollowUpVarianceStore(_ inner: MemoryDefaultFollowUpVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultFollowUpVarianceStore {
        return CachedDefaultFollowUpVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default follow up variances. Empty fields match all.
    final class DefaultFollowUpVarianceQuery {
        var category: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultFollowUpVariance) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultFollowUpVariance]) -> [DefaultFollowUpVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultFollowUpVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultFollowUpVariances(_ store: any DefaultFollowUpVarianceStore, query: DefaultFollowUpVarianceQuery) -> [DefaultFollowUpVariance] {
        return query.apply(store.list())
    }
}
