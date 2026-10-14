import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense policies by code.
    protocol DispensePolicyStore {
        func find(_ code: String) -> DispensePolicy?
        func save(_ item: DispensePolicy)
        func remove(_ code: String) -> Bool
        func list() -> [DispensePolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispensePolicyStore: DispensePolicyStore {
        var items: [String: DispensePolicy]
        var order: [String]

        init(items: [String: DispensePolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispensePolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispensePolicy) {
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

        func list() -> [DispensePolicy] {
            var out: [DispensePolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispensePolicyStore() -> any DispensePolicyStore {
        return MemoryDispensePolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispensePolicyStore: DispensePolicyStore {
        var inner: MemoryDispensePolicyStore
        var cache: TTLCache<DispensePolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispensePolicyStore, cache: TTLCache<DispensePolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispensePolicy? {
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

        func save(_ item: DispensePolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispensePolicy] {
            return inner.list()
        }
    }

    static func newCachedDispensePolicyStore(_ inner: MemoryDispensePolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispensePolicyStore {
        return CachedDispensePolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense policies. Empty fields match all.
    final class DispensePolicyQuery {
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

        func matches(_ item: DispensePolicy) -> Bool {
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

        func apply(_ items: [DispensePolicy]) -> [DispensePolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispensePolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispensePolicies(_ store: any DispensePolicyStore, query: DispensePolicyQuery) -> [DispensePolicy] {
        return query.apply(store.list())
    }
}
