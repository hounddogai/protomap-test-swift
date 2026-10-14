import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range policies by code.
    protocol ReferenceRangePolicyStore {
        func find(_ code: String) -> ReferenceRangePolicy?
        func save(_ item: ReferenceRangePolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangePolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangePolicyStore: ReferenceRangePolicyStore {
        var items: [String: ReferenceRangePolicy]
        var order: [String]

        init(items: [String: ReferenceRangePolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangePolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangePolicy) {
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

        func list() -> [ReferenceRangePolicy] {
            var out: [ReferenceRangePolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangePolicyStore() -> any ReferenceRangePolicyStore {
        return MemoryReferenceRangePolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangePolicyStore: ReferenceRangePolicyStore {
        var inner: MemoryReferenceRangePolicyStore
        var cache: TTLCache<ReferenceRangePolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangePolicyStore, cache: TTLCache<ReferenceRangePolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangePolicy? {
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

        func save(_ item: ReferenceRangePolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangePolicy] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangePolicyStore(_ inner: MemoryReferenceRangePolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangePolicyStore {
        return CachedReferenceRangePolicyStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range policies. Empty fields match all.
    final class ReferenceRangePolicyQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangePolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangePolicy]) -> [ReferenceRangePolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangePolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangePolicies(_ store: any ReferenceRangePolicyStore, query: ReferenceRangePolicyQuery) -> [ReferenceRangePolicy] {
        return query.apply(store.list())
    }
}
