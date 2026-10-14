import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps regional care gap bundles by code.
    protocol RegionalCareGapBundleStore {
        func find(_ code: String) -> RegionalCareGapBundle?
        func save(_ item: RegionalCareGapBundle)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalCareGapBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalCareGapBundleStore: RegionalCareGapBundleStore {
        var items: [String: RegionalCareGapBundle]
        var order: [String]

        init(items: [String: RegionalCareGapBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalCareGapBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalCareGapBundle) {
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

        func list() -> [RegionalCareGapBundle] {
            var out: [RegionalCareGapBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalCareGapBundleStore() -> any RegionalCareGapBundleStore {
        return MemoryRegionalCareGapBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalCareGapBundleStore: RegionalCareGapBundleStore {
        var inner: MemoryRegionalCareGapBundleStore
        var cache: TTLCache<RegionalCareGapBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalCareGapBundleStore, cache: TTLCache<RegionalCareGapBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalCareGapBundle? {
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

        func save(_ item: RegionalCareGapBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalCareGapBundle] {
            return inner.list()
        }
    }

    static func newCachedRegionalCareGapBundleStore(_ inner: MemoryRegionalCareGapBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalCareGapBundleStore {
        return CachedRegionalCareGapBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional care gap bundles. Empty fields match all.
    final class RegionalCareGapBundleQuery {
        var source: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalCareGapBundle) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalCareGapBundle]) -> [RegionalCareGapBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalCareGapBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalCareGapBundles(_ store: any RegionalCareGapBundleStore, query: RegionalCareGapBundleQuery) -> [RegionalCareGapBundle] {
        return query.apply(store.list())
    }
}
