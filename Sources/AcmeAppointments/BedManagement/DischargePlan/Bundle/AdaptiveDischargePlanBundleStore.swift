import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive discharge plan bundles by code.
    protocol AdaptiveDischargePlanBundleStore {
        func find(_ code: String) -> AdaptiveDischargePlanBundle?
        func save(_ item: AdaptiveDischargePlanBundle)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveDischargePlanBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveDischargePlanBundleStore: AdaptiveDischargePlanBundleStore {
        var items: [String: AdaptiveDischargePlanBundle]
        var order: [String]

        init(items: [String: AdaptiveDischargePlanBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveDischargePlanBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveDischargePlanBundle) {
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

        func list() -> [AdaptiveDischargePlanBundle] {
            var out: [AdaptiveDischargePlanBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveDischargePlanBundleStore() -> any AdaptiveDischargePlanBundleStore {
        return MemoryAdaptiveDischargePlanBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveDischargePlanBundleStore: AdaptiveDischargePlanBundleStore {
        var inner: MemoryAdaptiveDischargePlanBundleStore
        var cache: TTLCache<AdaptiveDischargePlanBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveDischargePlanBundleStore, cache: TTLCache<AdaptiveDischargePlanBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveDischargePlanBundle? {
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

        func save(_ item: AdaptiveDischargePlanBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveDischargePlanBundle] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveDischargePlanBundleStore(_ inner: MemoryAdaptiveDischargePlanBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveDischargePlanBundleStore {
        return CachedAdaptiveDischargePlanBundleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive discharge plan bundles. Empty fields match all.
    final class AdaptiveDischargePlanBundleQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveDischargePlanBundle) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveDischargePlanBundle]) -> [AdaptiveDischargePlanBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveDischargePlanBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveDischargePlanBundles(_ store: any AdaptiveDischargePlanBundleStore, query: AdaptiveDischargePlanBundleQuery) -> [AdaptiveDischargePlanBundle] {
        return query.apply(store.list())
    }
}
