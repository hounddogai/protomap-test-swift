import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual program bundles by code.
    protocol ManualProgramBundleStore {
        func find(_ code: String) -> ManualProgramBundle?
        func save(_ item: ManualProgramBundle)
        func remove(_ code: String) -> Bool
        func list() -> [ManualProgramBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualProgramBundleStore: ManualProgramBundleStore {
        var items: [String: ManualProgramBundle]
        var order: [String]

        init(items: [String: ManualProgramBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualProgramBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualProgramBundle) {
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

        func list() -> [ManualProgramBundle] {
            var out: [ManualProgramBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualProgramBundleStore() -> any ManualProgramBundleStore {
        return MemoryManualProgramBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualProgramBundleStore: ManualProgramBundleStore {
        var inner: MemoryManualProgramBundleStore
        var cache: TTLCache<ManualProgramBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualProgramBundleStore, cache: TTLCache<ManualProgramBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualProgramBundle? {
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

        func save(_ item: ManualProgramBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualProgramBundle] {
            return inner.list()
        }
    }

    static func newCachedManualProgramBundleStore(_ inner: MemoryManualProgramBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualProgramBundleStore {
        return CachedManualProgramBundleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual program bundles. Empty fields match all.
    final class ManualProgramBundleQuery {
        var region: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCost: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualProgramBundle) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualProgramBundle]) -> [ManualProgramBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualProgramBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualProgramBundles(_ store: any ManualProgramBundleStore, query: ManualProgramBundleQuery) -> [ManualProgramBundle] {
        return query.apply(store.list())
    }
}
