import AcmePlatform
import Foundation

extension Consent {
    /// Keeps adaptive revocation bundles by code.
    protocol AdaptiveRevocationBundleStore {
        func find(_ code: String) -> AdaptiveRevocationBundle?
        func save(_ item: AdaptiveRevocationBundle)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveRevocationBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveRevocationBundleStore: AdaptiveRevocationBundleStore {
        var items: [String: AdaptiveRevocationBundle]
        var order: [String]

        init(items: [String: AdaptiveRevocationBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveRevocationBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveRevocationBundle) {
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

        func list() -> [AdaptiveRevocationBundle] {
            var out: [AdaptiveRevocationBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveRevocationBundleStore() -> any AdaptiveRevocationBundleStore {
        return MemoryAdaptiveRevocationBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveRevocationBundleStore: AdaptiveRevocationBundleStore {
        var inner: MemoryAdaptiveRevocationBundleStore
        var cache: TTLCache<AdaptiveRevocationBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveRevocationBundleStore, cache: TTLCache<AdaptiveRevocationBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveRevocationBundle? {
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

        func save(_ item: AdaptiveRevocationBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveRevocationBundle] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveRevocationBundleStore(_ inner: MemoryAdaptiveRevocationBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveRevocationBundleStore {
        return CachedAdaptiveRevocationBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive revocation bundles. Empty fields match all.
    final class AdaptiveRevocationBundleQuery {
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

        func matches(_ item: AdaptiveRevocationBundle) -> Bool {
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

        func apply(_ items: [AdaptiveRevocationBundle]) -> [AdaptiveRevocationBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveRevocationBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveRevocationBundles(_ store: any AdaptiveRevocationBundleStore, query: AdaptiveRevocationBundleQuery) -> [AdaptiveRevocationBundle] {
        return query.apply(store.list())
    }
}
