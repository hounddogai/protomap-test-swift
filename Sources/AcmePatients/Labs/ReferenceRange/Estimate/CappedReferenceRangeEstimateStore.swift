import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped reference range estimates by code.
    protocol CappedReferenceRangeEstimateStore {
        func find(_ code: String) -> CappedReferenceRangeEstimate?
        func save(_ item: CappedReferenceRangeEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [CappedReferenceRangeEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedReferenceRangeEstimateStore: CappedReferenceRangeEstimateStore {
        var items: [String: CappedReferenceRangeEstimate]
        var order: [String]

        init(items: [String: CappedReferenceRangeEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedReferenceRangeEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedReferenceRangeEstimate) {
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

        func list() -> [CappedReferenceRangeEstimate] {
            var out: [CappedReferenceRangeEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedReferenceRangeEstimateStore() -> any CappedReferenceRangeEstimateStore {
        return MemoryCappedReferenceRangeEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedReferenceRangeEstimateStore: CappedReferenceRangeEstimateStore {
        var inner: MemoryCappedReferenceRangeEstimateStore
        var cache: TTLCache<CappedReferenceRangeEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedReferenceRangeEstimateStore, cache: TTLCache<CappedReferenceRangeEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedReferenceRangeEstimate? {
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

        func save(_ item: CappedReferenceRangeEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedReferenceRangeEstimate] {
            return inner.list()
        }
    }

    static func newCachedCappedReferenceRangeEstimateStore(_ inner: MemoryCappedReferenceRangeEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedReferenceRangeEstimateStore {
        return CachedCappedReferenceRangeEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped reference range estimates. Empty fields match all.
    final class CappedReferenceRangeEstimateQuery {
        var category: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedReferenceRangeEstimate) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedReferenceRangeEstimate]) -> [CappedReferenceRangeEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedReferenceRangeEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedReferenceRangeEstimates(_ store: any CappedReferenceRangeEstimateStore, query: CappedReferenceRangeEstimateQuery) -> [CappedReferenceRangeEstimate] {
        return query.apply(store.list())
    }
}
