import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict acuity plan bundles by code.
    protocol StrictAcuityPlanBundleStore {
        func find(_ code: String) -> StrictAcuityPlanBundle?
        func save(_ item: StrictAcuityPlanBundle)
        func remove(_ code: String) -> Bool
        func list() -> [StrictAcuityPlanBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictAcuityPlanBundleStore: StrictAcuityPlanBundleStore {
        var items: [String: StrictAcuityPlanBundle]
        var order: [String]

        init(items: [String: StrictAcuityPlanBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictAcuityPlanBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictAcuityPlanBundle) {
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

        func list() -> [StrictAcuityPlanBundle] {
            var out: [StrictAcuityPlanBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictAcuityPlanBundleStore() -> any StrictAcuityPlanBundleStore {
        return MemoryStrictAcuityPlanBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictAcuityPlanBundleStore: StrictAcuityPlanBundleStore {
        var inner: MemoryStrictAcuityPlanBundleStore
        var cache: TTLCache<StrictAcuityPlanBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictAcuityPlanBundleStore, cache: TTLCache<StrictAcuityPlanBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictAcuityPlanBundle? {
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

        func save(_ item: StrictAcuityPlanBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictAcuityPlanBundle] {
            return inner.list()
        }
    }

    static func newCachedStrictAcuityPlanBundleStore(_ inner: MemoryStrictAcuityPlanBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictAcuityPlanBundleStore {
        return CachedStrictAcuityPlanBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict acuity plan bundles. Empty fields match all.
    final class StrictAcuityPlanBundleQuery {
        var unit: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRevision: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictAcuityPlanBundle) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictAcuityPlanBundle]) -> [StrictAcuityPlanBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictAcuityPlanBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictAcuityPlanBundles(_ store: any StrictAcuityPlanBundleStore, query: StrictAcuityPlanBundleQuery) -> [StrictAcuityPlanBundle] {
        return query.apply(store.list())
    }
}
