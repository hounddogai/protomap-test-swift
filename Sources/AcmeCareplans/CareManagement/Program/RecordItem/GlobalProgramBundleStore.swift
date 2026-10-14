import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global program bundles by code.
    protocol GlobalProgramBundleStore {
        func find(_ code: String) -> GlobalProgramBundle?
        func save(_ item: GlobalProgramBundle)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalProgramBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalProgramBundleStore: GlobalProgramBundleStore {
        var items: [String: GlobalProgramBundle]
        var order: [String]

        init(items: [String: GlobalProgramBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalProgramBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalProgramBundle) {
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

        func list() -> [GlobalProgramBundle] {
            var out: [GlobalProgramBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalProgramBundleStore() -> any GlobalProgramBundleStore {
        return MemoryGlobalProgramBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalProgramBundleStore: GlobalProgramBundleStore {
        var inner: MemoryGlobalProgramBundleStore
        var cache: TTLCache<GlobalProgramBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalProgramBundleStore, cache: TTLCache<GlobalProgramBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalProgramBundle? {
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

        func save(_ item: GlobalProgramBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalProgramBundle] {
            return inner.list()
        }
    }

    static func newCachedGlobalProgramBundleStore(_ inner: MemoryGlobalProgramBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalProgramBundleStore {
        return CachedGlobalProgramBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global program bundles. Empty fields match all.
    final class GlobalProgramBundleQuery {
        var region: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalProgramBundle) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalProgramBundle]) -> [GlobalProgramBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalProgramBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalProgramBundles(_ store: any GlobalProgramBundleStore, query: GlobalProgramBundleQuery) -> [GlobalProgramBundle] {
        return query.apply(store.list())
    }
}
