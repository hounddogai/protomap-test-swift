import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict shift bundles by code.
    protocol StrictShiftBundleStore {
        func find(_ code: String) -> StrictShiftBundle?
        func save(_ item: StrictShiftBundle)
        func remove(_ code: String) -> Bool
        func list() -> [StrictShiftBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictShiftBundleStore: StrictShiftBundleStore {
        var items: [String: StrictShiftBundle]
        var order: [String]

        init(items: [String: StrictShiftBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictShiftBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictShiftBundle) {
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

        func list() -> [StrictShiftBundle] {
            var out: [StrictShiftBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictShiftBundleStore() -> any StrictShiftBundleStore {
        return MemoryStrictShiftBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictShiftBundleStore: StrictShiftBundleStore {
        var inner: MemoryStrictShiftBundleStore
        var cache: TTLCache<StrictShiftBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictShiftBundleStore, cache: TTLCache<StrictShiftBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictShiftBundle? {
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

        func save(_ item: StrictShiftBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictShiftBundle] {
            return inner.list()
        }
    }

    static func newCachedStrictShiftBundleStore(_ inner: MemoryStrictShiftBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictShiftBundleStore {
        return CachedStrictShiftBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict shift bundles. Empty fields match all.
    final class StrictShiftBundleQuery {
        var ward: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictShiftBundle) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictShiftBundle]) -> [StrictShiftBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictShiftBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictShiftBundles(_ store: any StrictShiftBundleStore, query: StrictShiftBundleQuery) -> [StrictShiftBundle] {
        return query.apply(store.list())
    }
}
