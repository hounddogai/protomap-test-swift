import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled network bundles by code.
    protocol ScheduledNetworkBundleStore {
        func find(_ code: String) -> ScheduledNetworkBundle?
        func save(_ item: ScheduledNetworkBundle)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledNetworkBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledNetworkBundleStore: ScheduledNetworkBundleStore {
        var items: [String: ScheduledNetworkBundle]
        var order: [String]

        init(items: [String: ScheduledNetworkBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledNetworkBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledNetworkBundle) {
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

        func list() -> [ScheduledNetworkBundle] {
            var out: [ScheduledNetworkBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledNetworkBundleStore() -> any ScheduledNetworkBundleStore {
        return MemoryScheduledNetworkBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledNetworkBundleStore: ScheduledNetworkBundleStore {
        var inner: MemoryScheduledNetworkBundleStore
        var cache: TTLCache<ScheduledNetworkBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledNetworkBundleStore, cache: TTLCache<ScheduledNetworkBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledNetworkBundle? {
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

        func save(_ item: ScheduledNetworkBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledNetworkBundle] {
            return inner.list()
        }
    }

    static func newCachedScheduledNetworkBundleStore(_ inner: MemoryScheduledNetworkBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledNetworkBundleStore {
        return CachedScheduledNetworkBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled network bundles. Empty fields match all.
    final class ScheduledNetworkBundleQuery {
        var label: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledNetworkBundle) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ScheduledNetworkBundle]) -> [ScheduledNetworkBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledNetworkBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledNetworkBundles(_ store: any ScheduledNetworkBundleStore, query: ScheduledNetworkBundleQuery) -> [ScheduledNetworkBundle] {
        return query.apply(store.list())
    }
}
