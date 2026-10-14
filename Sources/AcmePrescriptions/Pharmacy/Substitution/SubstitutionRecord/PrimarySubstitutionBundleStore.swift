import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps primary substitution bundles by code.
    protocol PrimarySubstitutionBundleStore {
        func find(_ code: String) -> PrimarySubstitutionBundle?
        func save(_ item: PrimarySubstitutionBundle)
        func remove(_ code: String) -> Bool
        func list() -> [PrimarySubstitutionBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimarySubstitutionBundleStore: PrimarySubstitutionBundleStore {
        var items: [String: PrimarySubstitutionBundle]
        var order: [String]

        init(items: [String: PrimarySubstitutionBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimarySubstitutionBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimarySubstitutionBundle) {
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

        func list() -> [PrimarySubstitutionBundle] {
            var out: [PrimarySubstitutionBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimarySubstitutionBundleStore() -> any PrimarySubstitutionBundleStore {
        return MemoryPrimarySubstitutionBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimarySubstitutionBundleStore: PrimarySubstitutionBundleStore {
        var inner: MemoryPrimarySubstitutionBundleStore
        var cache: TTLCache<PrimarySubstitutionBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimarySubstitutionBundleStore, cache: TTLCache<PrimarySubstitutionBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimarySubstitutionBundle? {
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

        func save(_ item: PrimarySubstitutionBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimarySubstitutionBundle] {
            return inner.list()
        }
    }

    static func newCachedPrimarySubstitutionBundleStore(_ inner: MemoryPrimarySubstitutionBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimarySubstitutionBundleStore {
        return CachedPrimarySubstitutionBundleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary substitution bundles. Empty fields match all.
    final class PrimarySubstitutionBundleQuery {
        var name: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRetries: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimarySubstitutionBundle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimarySubstitutionBundle]) -> [PrimarySubstitutionBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimarySubstitutionBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimarySubstitutionBundles(_ store: any PrimarySubstitutionBundleStore, query: PrimarySubstitutionBundleQuery) -> [PrimarySubstitutionBundle] {
        return query.apply(store.list())
    }
}
