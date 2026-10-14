import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps regional care gap estimates by code.
    protocol RegionalCareGapEstimateStore {
        func find(_ code: String) -> RegionalCareGapEstimate?
        func save(_ item: RegionalCareGapEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalCareGapEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalCareGapEstimateStore: RegionalCareGapEstimateStore {
        var items: [String: RegionalCareGapEstimate]
        var order: [String]

        init(items: [String: RegionalCareGapEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalCareGapEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalCareGapEstimate) {
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

        func list() -> [RegionalCareGapEstimate] {
            var out: [RegionalCareGapEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalCareGapEstimateStore() -> any RegionalCareGapEstimateStore {
        return MemoryRegionalCareGapEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalCareGapEstimateStore: RegionalCareGapEstimateStore {
        var inner: MemoryRegionalCareGapEstimateStore
        var cache: TTLCache<RegionalCareGapEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalCareGapEstimateStore, cache: TTLCache<RegionalCareGapEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalCareGapEstimate? {
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

        func save(_ item: RegionalCareGapEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalCareGapEstimate] {
            return inner.list()
        }
    }

    static func newCachedRegionalCareGapEstimateStore(_ inner: MemoryRegionalCareGapEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalCareGapEstimateStore {
        return CachedRegionalCareGapEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional care gap estimates. Empty fields match all.
    final class RegionalCareGapEstimateQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalCareGapEstimate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalCareGapEstimate]) -> [RegionalCareGapEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalCareGapEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalCareGapEstimates(_ store: any RegionalCareGapEstimateStore, query: RegionalCareGapEstimateQuery) -> [RegionalCareGapEstimate] {
        return query.apply(store.list())
    }
}
