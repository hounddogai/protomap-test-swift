import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier bundles by code.
    protocol CourierBundleStore {
        func find(_ code: String) -> CourierBundle?
        func save(_ item: CourierBundle)
        func remove(_ code: String) -> Bool
        func list() -> [CourierBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierBundleStore: CourierBundleStore {
        var items: [String: CourierBundle]
        var order: [String]

        init(items: [String: CourierBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierBundle) {
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

        func list() -> [CourierBundle] {
            var out: [CourierBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierBundleStore() -> any CourierBundleStore {
        return MemoryCourierBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierBundleStore: CourierBundleStore {
        var inner: MemoryCourierBundleStore
        var cache: TTLCache<CourierBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierBundleStore, cache: TTLCache<CourierBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierBundle? {
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

        func save(_ item: CourierBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierBundle] {
            return inner.list()
        }
    }

    static func newCachedCourierBundleStore(_ inner: MemoryCourierBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierBundleStore {
        return CachedCourierBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier bundles. Empty fields match all.
    final class CourierBundleQuery {
        var region: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierBundle) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [CourierBundle]) -> [CourierBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierBundles(_ store: any CourierBundleStore, query: CourierBundleQuery) -> [CourierBundle] {
        return query.apply(store.list())
    }
}
