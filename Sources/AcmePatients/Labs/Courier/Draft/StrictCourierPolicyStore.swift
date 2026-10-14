import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict courier policies by code.
    protocol StrictCourierPolicyStore {
        func find(_ code: String) -> StrictCourierPolicy?
        func save(_ item: StrictCourierPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [StrictCourierPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictCourierPolicyStore: StrictCourierPolicyStore {
        var items: [String: StrictCourierPolicy]
        var order: [String]

        init(items: [String: StrictCourierPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictCourierPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictCourierPolicy) {
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

        func list() -> [StrictCourierPolicy] {
            var out: [StrictCourierPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictCourierPolicyStore() -> any StrictCourierPolicyStore {
        return MemoryStrictCourierPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictCourierPolicyStore: StrictCourierPolicyStore {
        var inner: MemoryStrictCourierPolicyStore
        var cache: TTLCache<StrictCourierPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictCourierPolicyStore, cache: TTLCache<StrictCourierPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictCourierPolicy? {
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

        func save(_ item: StrictCourierPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictCourierPolicy] {
            return inner.list()
        }
    }

    static func newCachedStrictCourierPolicyStore(_ inner: MemoryStrictCourierPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictCourierPolicyStore {
        return CachedStrictCourierPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict courier policies. Empty fields match all.
    final class StrictCourierPolicyQuery {
        var locale: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictCourierPolicy) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictCourierPolicy]) -> [StrictCourierPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictCourierPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictCourierPolicies(_ store: any StrictCourierPolicyStore, query: StrictCourierPolicyQuery) -> [StrictCourierPolicy] {
        return query.apply(store.list())
    }
}
