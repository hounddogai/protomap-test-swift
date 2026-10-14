import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary policies by code.
    protocol FormularyPolicyStore {
        func find(_ code: String) -> FormularyPolicy?
        func save(_ item: FormularyPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyPolicyStore: FormularyPolicyStore {
        var items: [String: FormularyPolicy]
        var order: [String]

        init(items: [String: FormularyPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyPolicy) {
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

        func list() -> [FormularyPolicy] {
            var out: [FormularyPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyPolicyStore() -> any FormularyPolicyStore {
        return MemoryFormularyPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyPolicyStore: FormularyPolicyStore {
        var inner: MemoryFormularyPolicyStore
        var cache: TTLCache<FormularyPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyPolicyStore, cache: TTLCache<FormularyPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyPolicy? {
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

        func save(_ item: FormularyPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyPolicy] {
            return inner.list()
        }
    }

    static func newCachedFormularyPolicyStore(_ inner: MemoryFormularyPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyPolicyStore {
        return CachedFormularyPolicyStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary policies. Empty fields match all.
    final class FormularyPolicyQuery {
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

        func matches(_ item: FormularyPolicy) -> Bool {
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

        func apply(_ items: [FormularyPolicy]) -> [FormularyPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyPolicies(_ store: any FormularyPolicyStore, query: FormularyPolicyQuery) -> [FormularyPolicy] {
        return query.apply(store.list())
    }
}
