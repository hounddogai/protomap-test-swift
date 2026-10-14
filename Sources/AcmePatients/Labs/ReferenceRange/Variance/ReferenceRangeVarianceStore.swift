import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range variances by code.
    protocol ReferenceRangeVarianceStore {
        func find(_ code: String) -> ReferenceRangeVariance?
        func save(_ item: ReferenceRangeVariance)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeVarianceStore: ReferenceRangeVarianceStore {
        var items: [String: ReferenceRangeVariance]
        var order: [String]

        init(items: [String: ReferenceRangeVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeVariance) {
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

        func list() -> [ReferenceRangeVariance] {
            var out: [ReferenceRangeVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeVarianceStore() -> any ReferenceRangeVarianceStore {
        return MemoryReferenceRangeVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeVarianceStore: ReferenceRangeVarianceStore {
        var inner: MemoryReferenceRangeVarianceStore
        var cache: TTLCache<ReferenceRangeVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeVarianceStore, cache: TTLCache<ReferenceRangeVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeVariance? {
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

        func save(_ item: ReferenceRangeVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeVariance] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeVarianceStore(_ inner: MemoryReferenceRangeVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeVarianceStore {
        return CachedReferenceRangeVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range variances. Empty fields match all.
    final class ReferenceRangeVarianceQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeVariance) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeVariance]) -> [ReferenceRangeVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeVariances(_ store: any ReferenceRangeVarianceStore, query: ReferenceRangeVarianceQuery) -> [ReferenceRangeVariance] {
        return query.apply(store.list())
    }
}
