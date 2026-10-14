import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback specimen bundles by code.
    protocol FallbackSpecimenBundleStore {
        func find(_ code: String) -> FallbackSpecimenBundle?
        func save(_ item: FallbackSpecimenBundle)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackSpecimenBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackSpecimenBundleStore: FallbackSpecimenBundleStore {
        var items: [String: FallbackSpecimenBundle]
        var order: [String]

        init(items: [String: FallbackSpecimenBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackSpecimenBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackSpecimenBundle) {
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

        func list() -> [FallbackSpecimenBundle] {
            var out: [FallbackSpecimenBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackSpecimenBundleStore() -> any FallbackSpecimenBundleStore {
        return MemoryFallbackSpecimenBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackSpecimenBundleStore: FallbackSpecimenBundleStore {
        var inner: MemoryFallbackSpecimenBundleStore
        var cache: TTLCache<FallbackSpecimenBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackSpecimenBundleStore, cache: TTLCache<FallbackSpecimenBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackSpecimenBundle? {
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

        func save(_ item: FallbackSpecimenBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackSpecimenBundle] {
            return inner.list()
        }
    }

    static func newCachedFallbackSpecimenBundleStore(_ inner: MemoryFallbackSpecimenBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackSpecimenBundleStore {
        return CachedFallbackSpecimenBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback specimen bundles. Empty fields match all.
    final class FallbackSpecimenBundleQuery {
        var unit: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackSpecimenBundle) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackSpecimenBundle]) -> [FallbackSpecimenBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackSpecimenBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackSpecimenBundles(_ store: any FallbackSpecimenBundleStore, query: FallbackSpecimenBundleQuery) -> [FallbackSpecimenBundle] {
        return query.apply(store.list())
    }
}
