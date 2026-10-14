import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding bundles by code.
    protocol RoundingBundleStore {
        func find(_ code: String) -> RoundingBundle?
        func save(_ item: RoundingBundle)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingBundleStore: RoundingBundleStore {
        var items: [String: RoundingBundle]
        var order: [String]

        init(items: [String: RoundingBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingBundle) {
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

        func list() -> [RoundingBundle] {
            var out: [RoundingBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingBundleStore() -> any RoundingBundleStore {
        return MemoryRoundingBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingBundleStore: RoundingBundleStore {
        var inner: MemoryRoundingBundleStore
        var cache: TTLCache<RoundingBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingBundleStore, cache: TTLCache<RoundingBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingBundle? {
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

        func save(_ item: RoundingBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingBundle] {
            return inner.list()
        }
    }

    static func newCachedRoundingBundleStore(_ inner: MemoryRoundingBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingBundleStore {
        return CachedRoundingBundleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding bundles. Empty fields match all.
    final class RoundingBundleQuery {
        var facility: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingBundle) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingBundle]) -> [RoundingBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingBundles(_ store: any RoundingBundleStore, query: RoundingBundleQuery) -> [RoundingBundle] {
        return query.apply(store.list())
    }
}
