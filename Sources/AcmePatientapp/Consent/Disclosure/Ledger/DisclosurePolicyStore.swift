import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure policies by code.
    protocol DisclosurePolicyStore {
        func find(_ code: String) -> DisclosurePolicy?
        func save(_ item: DisclosurePolicy)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosurePolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosurePolicyStore: DisclosurePolicyStore {
        var items: [String: DisclosurePolicy]
        var order: [String]

        init(items: [String: DisclosurePolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosurePolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosurePolicy) {
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

        func list() -> [DisclosurePolicy] {
            var out: [DisclosurePolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosurePolicyStore() -> any DisclosurePolicyStore {
        return MemoryDisclosurePolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosurePolicyStore: DisclosurePolicyStore {
        var inner: MemoryDisclosurePolicyStore
        var cache: TTLCache<DisclosurePolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosurePolicyStore, cache: TTLCache<DisclosurePolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosurePolicy? {
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

        func save(_ item: DisclosurePolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosurePolicy] {
            return inner.list()
        }
    }

    static func newCachedDisclosurePolicyStore(_ inner: MemoryDisclosurePolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosurePolicyStore {
        return CachedDisclosurePolicyStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure policies. Empty fields match all.
    final class DisclosurePolicyQuery {
        var segment: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosurePolicy) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosurePolicy]) -> [DisclosurePolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosurePolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosurePolicies(_ store: any DisclosurePolicyStore, query: DisclosurePolicyQuery) -> [DisclosurePolicy] {
        return query.apply(store.list())
    }
}
