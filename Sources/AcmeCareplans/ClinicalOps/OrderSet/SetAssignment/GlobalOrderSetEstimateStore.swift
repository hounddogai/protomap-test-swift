import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global order set estimates by code.
    protocol GlobalOrderSetEstimateStore {
        func find(_ code: String) -> GlobalOrderSetEstimate?
        func save(_ item: GlobalOrderSetEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalOrderSetEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalOrderSetEstimateStore: GlobalOrderSetEstimateStore {
        var items: [String: GlobalOrderSetEstimate]
        var order: [String]

        init(items: [String: GlobalOrderSetEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalOrderSetEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalOrderSetEstimate) {
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

        func list() -> [GlobalOrderSetEstimate] {
            var out: [GlobalOrderSetEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalOrderSetEstimateStore() -> any GlobalOrderSetEstimateStore {
        return MemoryGlobalOrderSetEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalOrderSetEstimateStore: GlobalOrderSetEstimateStore {
        var inner: MemoryGlobalOrderSetEstimateStore
        var cache: TTLCache<GlobalOrderSetEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalOrderSetEstimateStore, cache: TTLCache<GlobalOrderSetEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalOrderSetEstimate? {
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

        func save(_ item: GlobalOrderSetEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalOrderSetEstimate] {
            return inner.list()
        }
    }

    static func newCachedGlobalOrderSetEstimateStore(_ inner: MemoryGlobalOrderSetEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalOrderSetEstimateStore {
        return CachedGlobalOrderSetEstimateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global order set estimates. Empty fields match all.
    final class GlobalOrderSetEstimateQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalOrderSetEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalOrderSetEstimate]) -> [GlobalOrderSetEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalOrderSetEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalOrderSetEstimates(_ store: any GlobalOrderSetEstimateStore, query: GlobalOrderSetEstimateQuery) -> [GlobalOrderSetEstimate] {
        return query.apply(store.list())
    }
}
