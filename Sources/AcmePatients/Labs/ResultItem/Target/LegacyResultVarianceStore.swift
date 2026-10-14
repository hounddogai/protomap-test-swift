import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy result variances by code.
    protocol LegacyResultVarianceStore {
        func find(_ code: String) -> LegacyResultVariance?
        func save(_ item: LegacyResultVariance)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyResultVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyResultVarianceStore: LegacyResultVarianceStore {
        var items: [String: LegacyResultVariance]
        var order: [String]

        init(items: [String: LegacyResultVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyResultVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyResultVariance) {
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

        func list() -> [LegacyResultVariance] {
            var out: [LegacyResultVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyResultVarianceStore() -> any LegacyResultVarianceStore {
        return MemoryLegacyResultVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyResultVarianceStore: LegacyResultVarianceStore {
        var inner: MemoryLegacyResultVarianceStore
        var cache: TTLCache<LegacyResultVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyResultVarianceStore, cache: TTLCache<LegacyResultVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyResultVariance? {
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

        func save(_ item: LegacyResultVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyResultVariance] {
            return inner.list()
        }
    }

    static func newCachedLegacyResultVarianceStore(_ inner: MemoryLegacyResultVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyResultVarianceStore {
        return CachedLegacyResultVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy result variances. Empty fields match all.
    final class LegacyResultVarianceQuery {
        var category: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyResultVariance) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyResultVariance]) -> [LegacyResultVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyResultVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyResultVariances(_ store: any LegacyResultVarianceStore, query: LegacyResultVarianceQuery) -> [LegacyResultVariance] {
        return query.apply(store.list())
    }
}
