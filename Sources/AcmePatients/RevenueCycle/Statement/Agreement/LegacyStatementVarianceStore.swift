import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy statement variances by code.
    protocol LegacyStatementVarianceStore {
        func find(_ code: String) -> LegacyStatementVariance?
        func save(_ item: LegacyStatementVariance)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyStatementVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyStatementVarianceStore: LegacyStatementVarianceStore {
        var items: [String: LegacyStatementVariance]
        var order: [String]

        init(items: [String: LegacyStatementVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyStatementVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyStatementVariance) {
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

        func list() -> [LegacyStatementVariance] {
            var out: [LegacyStatementVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyStatementVarianceStore() -> any LegacyStatementVarianceStore {
        return MemoryLegacyStatementVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyStatementVarianceStore: LegacyStatementVarianceStore {
        var inner: MemoryLegacyStatementVarianceStore
        var cache: TTLCache<LegacyStatementVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyStatementVarianceStore, cache: TTLCache<LegacyStatementVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyStatementVariance? {
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

        func save(_ item: LegacyStatementVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyStatementVariance] {
            return inner.list()
        }
    }

    static func newCachedLegacyStatementVarianceStore(_ inner: MemoryLegacyStatementVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyStatementVarianceStore {
        return CachedLegacyStatementVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy statement variances. Empty fields match all.
    final class LegacyStatementVarianceQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyStatementVariance) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyStatementVariance]) -> [LegacyStatementVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyStatementVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyStatementVariances(_ store: any LegacyStatementVarianceStore, query: LegacyStatementVarianceQuery) -> [LegacyStatementVariance] {
        return query.apply(store.list())
    }
}
