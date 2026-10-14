import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen policies by code.
    protocol SpecimenPolicyStore {
        func find(_ code: String) -> SpecimenPolicy?
        func save(_ item: SpecimenPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenPolicyStore: SpecimenPolicyStore {
        var items: [String: SpecimenPolicy]
        var order: [String]

        init(items: [String: SpecimenPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenPolicy) {
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

        func list() -> [SpecimenPolicy] {
            var out: [SpecimenPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenPolicyStore() -> any SpecimenPolicyStore {
        return MemorySpecimenPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenPolicyStore: SpecimenPolicyStore {
        var inner: MemorySpecimenPolicyStore
        var cache: TTLCache<SpecimenPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenPolicyStore, cache: TTLCache<SpecimenPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenPolicy? {
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

        func save(_ item: SpecimenPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenPolicy] {
            return inner.list()
        }
    }

    static func newCachedSpecimenPolicyStore(_ inner: MemorySpecimenPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenPolicyStore {
        return CachedSpecimenPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen policies. Empty fields match all.
    final class SpecimenPolicyQuery {
        var title: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRate: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenPolicy) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenPolicy]) -> [SpecimenPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenPolicies(_ store: any SpecimenPolicyStore, query: SpecimenPolicyQuery) -> [SpecimenPolicy] {
        return query.apply(store.list())
    }
}
