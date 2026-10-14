import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional specimen estimates by code.
    protocol RegionalSpecimenEstimateStore {
        func find(_ code: String) -> RegionalSpecimenEstimate?
        func save(_ item: RegionalSpecimenEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalSpecimenEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalSpecimenEstimateStore: RegionalSpecimenEstimateStore {
        var items: [String: RegionalSpecimenEstimate]
        var order: [String]

        init(items: [String: RegionalSpecimenEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalSpecimenEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalSpecimenEstimate) {
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

        func list() -> [RegionalSpecimenEstimate] {
            var out: [RegionalSpecimenEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalSpecimenEstimateStore() -> any RegionalSpecimenEstimateStore {
        return MemoryRegionalSpecimenEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalSpecimenEstimateStore: RegionalSpecimenEstimateStore {
        var inner: MemoryRegionalSpecimenEstimateStore
        var cache: TTLCache<RegionalSpecimenEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalSpecimenEstimateStore, cache: TTLCache<RegionalSpecimenEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalSpecimenEstimate? {
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

        func save(_ item: RegionalSpecimenEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalSpecimenEstimate] {
            return inner.list()
        }
    }

    static func newCachedRegionalSpecimenEstimateStore(_ inner: MemoryRegionalSpecimenEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalSpecimenEstimateStore {
        return CachedRegionalSpecimenEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional specimen estimates. Empty fields match all.
    final class RegionalSpecimenEstimateQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalSpecimenEstimate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalSpecimenEstimate]) -> [RegionalSpecimenEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalSpecimenEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalSpecimenEstimates(_ store: any RegionalSpecimenEstimateStore, query: RegionalSpecimenEstimateQuery) -> [RegionalSpecimenEstimate] {
        return query.apply(store.list())
    }
}
