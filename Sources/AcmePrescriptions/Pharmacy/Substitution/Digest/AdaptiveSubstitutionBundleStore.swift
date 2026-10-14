import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive substitution bundles by code.
    protocol AdaptiveSubstitutionBundleStore {
        func find(_ code: String) -> AdaptiveSubstitutionBundle?
        func save(_ item: AdaptiveSubstitutionBundle)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveSubstitutionBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveSubstitutionBundleStore: AdaptiveSubstitutionBundleStore {
        var items: [String: AdaptiveSubstitutionBundle]
        var order: [String]

        init(items: [String: AdaptiveSubstitutionBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveSubstitutionBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveSubstitutionBundle) {
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

        func list() -> [AdaptiveSubstitutionBundle] {
            var out: [AdaptiveSubstitutionBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveSubstitutionBundleStore() -> any AdaptiveSubstitutionBundleStore {
        return MemoryAdaptiveSubstitutionBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveSubstitutionBundleStore: AdaptiveSubstitutionBundleStore {
        var inner: MemoryAdaptiveSubstitutionBundleStore
        var cache: TTLCache<AdaptiveSubstitutionBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveSubstitutionBundleStore, cache: TTLCache<AdaptiveSubstitutionBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveSubstitutionBundle? {
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

        func save(_ item: AdaptiveSubstitutionBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveSubstitutionBundle] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveSubstitutionBundleStore(_ inner: MemoryAdaptiveSubstitutionBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveSubstitutionBundleStore {
        return CachedAdaptiveSubstitutionBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive substitution bundles. Empty fields match all.
    final class AdaptiveSubstitutionBundleQuery {
        var channel: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveSubstitutionBundle) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveSubstitutionBundle]) -> [AdaptiveSubstitutionBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveSubstitutionBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveSubstitutionBundles(_ store: any AdaptiveSubstitutionBundleStore, query: AdaptiveSubstitutionBundleQuery) -> [AdaptiveSubstitutionBundle] {
        return query.apply(store.list())
    }
}
