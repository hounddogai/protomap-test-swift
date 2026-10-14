import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps seasonal task estimates by code.
    protocol SeasonalTaskEstimateStore {
        func find(_ code: String) -> SeasonalTaskEstimate?
        func save(_ item: SeasonalTaskEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalTaskEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalTaskEstimateStore: SeasonalTaskEstimateStore {
        var items: [String: SeasonalTaskEstimate]
        var order: [String]

        init(items: [String: SeasonalTaskEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalTaskEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalTaskEstimate) {
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

        func list() -> [SeasonalTaskEstimate] {
            var out: [SeasonalTaskEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalTaskEstimateStore() -> any SeasonalTaskEstimateStore {
        return MemorySeasonalTaskEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalTaskEstimateStore: SeasonalTaskEstimateStore {
        var inner: MemorySeasonalTaskEstimateStore
        var cache: TTLCache<SeasonalTaskEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalTaskEstimateStore, cache: TTLCache<SeasonalTaskEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalTaskEstimate? {
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

        func save(_ item: SeasonalTaskEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalTaskEstimate] {
            return inner.list()
        }
    }

    static func newCachedSeasonalTaskEstimateStore(_ inner: MemorySeasonalTaskEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalTaskEstimateStore {
        return CachedSeasonalTaskEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal task estimates. Empty fields match all.
    final class SeasonalTaskEstimateQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalTaskEstimate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalTaskEstimate]) -> [SeasonalTaskEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalTaskEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalTaskEstimates(_ store: any SeasonalTaskEstimateStore, query: SeasonalTaskEstimateQuery) -> [SeasonalTaskEstimate] {
        return query.apply(store.list())
    }
}
