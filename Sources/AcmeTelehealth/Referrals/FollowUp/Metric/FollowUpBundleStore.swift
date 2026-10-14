import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up bundles by code.
    protocol FollowUpBundleStore {
        func find(_ code: String) -> FollowUpBundle?
        func save(_ item: FollowUpBundle)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpBundleStore: FollowUpBundleStore {
        var items: [String: FollowUpBundle]
        var order: [String]

        init(items: [String: FollowUpBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpBundle) {
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

        func list() -> [FollowUpBundle] {
            var out: [FollowUpBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpBundleStore() -> any FollowUpBundleStore {
        return MemoryFollowUpBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpBundleStore: FollowUpBundleStore {
        var inner: MemoryFollowUpBundleStore
        var cache: TTLCache<FollowUpBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpBundleStore, cache: TTLCache<FollowUpBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpBundle? {
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

        func save(_ item: FollowUpBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpBundle] {
            return inner.list()
        }
    }

    static func newCachedFollowUpBundleStore(_ inner: MemoryFollowUpBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpBundleStore {
        return CachedFollowUpBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up bundles. Empty fields match all.
    final class FollowUpBundleQuery {
        var label: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpBundle) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [FollowUpBundle]) -> [FollowUpBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpBundles(_ store: any FollowUpBundleStore, query: FollowUpBundleQuery) -> [FollowUpBundle] {
        return query.apply(store.list())
    }
}
