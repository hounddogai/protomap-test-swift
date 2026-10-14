import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution bundles by code.
    protocol SubstitutionBundleStore {
        func find(_ code: String) -> SubstitutionBundle?
        func save(_ item: SubstitutionBundle)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionBundleStore: SubstitutionBundleStore {
        var items: [String: SubstitutionBundle]
        var order: [String]

        init(items: [String: SubstitutionBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionBundle) {
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

        func list() -> [SubstitutionBundle] {
            var out: [SubstitutionBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionBundleStore() -> any SubstitutionBundleStore {
        return MemorySubstitutionBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionBundleStore: SubstitutionBundleStore {
        var inner: MemorySubstitutionBundleStore
        var cache: TTLCache<SubstitutionBundle>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionBundleStore, cache: TTLCache<SubstitutionBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionBundle? {
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

        func save(_ item: SubstitutionBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionBundle] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionBundleStore(_ inner: MemorySubstitutionBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionBundleStore {
        return CachedSubstitutionBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution bundles. Empty fields match all.
    final class SubstitutionBundleQuery {
        var ward: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minWeight: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionBundle) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionBundle]) -> [SubstitutionBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionBundles(_ store: any SubstitutionBundleStore, query: SubstitutionBundleQuery) -> [SubstitutionBundle] {
        return query.apply(store.list())
    }
}
