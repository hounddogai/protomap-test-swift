import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap bundles by code.
    protocol CareGapBundleStore {
        func find(_ code: String) -> CareGapBundle?
        func save(_ item: CareGapBundle)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapBundleStore: CareGapBundleStore {
        var items: [String: CareGapBundle]
        var order: [String]

        init(items: [String: CareGapBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapBundle) {
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

        func list() -> [CareGapBundle] {
            var out: [CareGapBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapBundleStore() -> any CareGapBundleStore {
        return MemoryCareGapBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapBundleStore: CareGapBundleStore {
        var inner: MemoryCareGapBundleStore
        var cache: TTLCache<CareGapBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapBundleStore, cache: TTLCache<CareGapBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapBundle? {
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

        func save(_ item: CareGapBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapBundle] {
            return inner.list()
        }
    }

    static func newCachedCareGapBundleStore(_ inner: MemoryCareGapBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapBundleStore {
        return CachedCareGapBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap bundles. Empty fields match all.
    final class CareGapBundleQuery {
        var ward: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minBudget: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapBundle) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapBundle]) -> [CareGapBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapBundles(_ store: any CareGapBundleStore, query: CareGapBundleQuery) -> [CareGapBundle] {
        return query.apply(store.list())
    }
}
