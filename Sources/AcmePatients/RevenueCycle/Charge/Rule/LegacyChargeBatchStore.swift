import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy charge batches by code.
    protocol LegacyChargeBatchStore {
        func find(_ code: String) -> LegacyChargeBatch?
        func save(_ item: LegacyChargeBatch)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyChargeBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyChargeBatchStore: LegacyChargeBatchStore {
        var items: [String: LegacyChargeBatch]
        var order: [String]

        init(items: [String: LegacyChargeBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyChargeBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyChargeBatch) {
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

        func list() -> [LegacyChargeBatch] {
            var out: [LegacyChargeBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyChargeBatchStore() -> any LegacyChargeBatchStore {
        return MemoryLegacyChargeBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyChargeBatchStore: LegacyChargeBatchStore {
        var inner: MemoryLegacyChargeBatchStore
        var cache: TTLCache<LegacyChargeBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyChargeBatchStore, cache: TTLCache<LegacyChargeBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyChargeBatch? {
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

        func save(_ item: LegacyChargeBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyChargeBatch] {
            return inner.list()
        }
    }

    static func newCachedLegacyChargeBatchStore(_ inner: MemoryLegacyChargeBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyChargeBatchStore {
        return CachedLegacyChargeBatchStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy charge batches. Empty fields match all.
    final class LegacyChargeBatchQuery {
        var region: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minRatio: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyChargeBatch) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyChargeBatch]) -> [LegacyChargeBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyChargeBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyChargeBatches(_ store: any LegacyChargeBatchStore, query: LegacyChargeBatchQuery) -> [LegacyChargeBatch] {
        return query.apply(store.list())
    }
}
