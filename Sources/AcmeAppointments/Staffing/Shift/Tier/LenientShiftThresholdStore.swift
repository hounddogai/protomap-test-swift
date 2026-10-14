import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps lenient shift thresholds by code.
    protocol LenientShiftThresholdStore {
        func find(_ code: String) -> LenientShiftThreshold?
        func save(_ item: LenientShiftThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [LenientShiftThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientShiftThresholdStore: LenientShiftThresholdStore {
        var items: [String: LenientShiftThreshold]
        var order: [String]

        init(items: [String: LenientShiftThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientShiftThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientShiftThreshold) {
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

        func list() -> [LenientShiftThreshold] {
            var out: [LenientShiftThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientShiftThresholdStore() -> any LenientShiftThresholdStore {
        return MemoryLenientShiftThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientShiftThresholdStore: LenientShiftThresholdStore {
        var inner: MemoryLenientShiftThresholdStore
        var cache: TTLCache<LenientShiftThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientShiftThresholdStore, cache: TTLCache<LenientShiftThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientShiftThreshold? {
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

        func save(_ item: LenientShiftThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientShiftThreshold] {
            return inner.list()
        }
    }

    static func newCachedLenientShiftThresholdStore(_ inner: MemoryLenientShiftThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientShiftThresholdStore {
        return CachedLenientShiftThresholdStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient shift thresholds. Empty fields match all.
    final class LenientShiftThresholdQuery {
        var region: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientShiftThreshold) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientShiftThreshold]) -> [LenientShiftThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientShiftThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientShiftThresholds(_ store: any LenientShiftThresholdStore, query: LenientShiftThresholdQuery) -> [LenientShiftThreshold] {
        return query.apply(store.list())
    }
}
