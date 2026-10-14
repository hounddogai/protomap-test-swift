import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict formulary policies by code.
    protocol StrictFormularyPolicyStore {
        func find(_ code: String) -> StrictFormularyPolicy?
        func save(_ item: StrictFormularyPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [StrictFormularyPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictFormularyPolicyStore: StrictFormularyPolicyStore {
        var items: [String: StrictFormularyPolicy]
        var order: [String]

        init(items: [String: StrictFormularyPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictFormularyPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictFormularyPolicy) {
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

        func list() -> [StrictFormularyPolicy] {
            var out: [StrictFormularyPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictFormularyPolicyStore() -> any StrictFormularyPolicyStore {
        return MemoryStrictFormularyPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictFormularyPolicyStore: StrictFormularyPolicyStore {
        var inner: MemoryStrictFormularyPolicyStore
        var cache: TTLCache<StrictFormularyPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictFormularyPolicyStore, cache: TTLCache<StrictFormularyPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictFormularyPolicy? {
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

        func save(_ item: StrictFormularyPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictFormularyPolicy] {
            return inner.list()
        }
    }

    static func newCachedStrictFormularyPolicyStore(_ inner: MemoryStrictFormularyPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictFormularyPolicyStore {
        return CachedStrictFormularyPolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict formulary policies. Empty fields match all.
    final class StrictFormularyPolicyQuery {
        var locale: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictFormularyPolicy) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictFormularyPolicy]) -> [StrictFormularyPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictFormularyPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictFormularyPolicies(_ store: any StrictFormularyPolicyStore, query: StrictFormularyPolicyQuery) -> [StrictFormularyPolicy] {
        return query.apply(store.list())
    }
}
