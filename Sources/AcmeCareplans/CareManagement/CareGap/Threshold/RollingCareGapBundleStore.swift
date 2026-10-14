import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling care gap bundles by code.
    protocol RollingCareGapBundleStore {
        func find(_ code: String) -> RollingCareGapBundle?
        func save(_ item: RollingCareGapBundle)
        func remove(_ code: String) -> Bool
        func list() -> [RollingCareGapBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingCareGapBundleStore: RollingCareGapBundleStore {
        var items: [String: RollingCareGapBundle]
        var order: [String]

        init(items: [String: RollingCareGapBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingCareGapBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingCareGapBundle) {
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

        func list() -> [RollingCareGapBundle] {
            var out: [RollingCareGapBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingCareGapBundleStore() -> any RollingCareGapBundleStore {
        return MemoryRollingCareGapBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingCareGapBundleStore: RollingCareGapBundleStore {
        var inner: MemoryRollingCareGapBundleStore
        var cache: TTLCache<RollingCareGapBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingCareGapBundleStore, cache: TTLCache<RollingCareGapBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingCareGapBundle? {
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

        func save(_ item: RollingCareGapBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingCareGapBundle] {
            return inner.list()
        }
    }

    static func newCachedRollingCareGapBundleStore(_ inner: MemoryRollingCareGapBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingCareGapBundleStore {
        return CachedRollingCareGapBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling care gap bundles. Empty fields match all.
    final class RollingCareGapBundleQuery {
        var locale: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minPriority: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingCareGapBundle) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingCareGapBundle]) -> [RollingCareGapBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingCareGapBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingCareGapBundles(_ store: any RollingCareGapBundleStore, query: RollingCareGapBundleQuery) -> [RollingCareGapBundle] {
        return query.apply(store.list())
    }
}
