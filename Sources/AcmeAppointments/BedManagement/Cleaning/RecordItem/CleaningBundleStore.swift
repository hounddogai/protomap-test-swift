import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning bundles by code.
    protocol CleaningBundleStore {
        func find(_ code: String) -> CleaningBundle?
        func save(_ item: CleaningBundle)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningBundleStore: CleaningBundleStore {
        var items: [String: CleaningBundle]
        var order: [String]

        init(items: [String: CleaningBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningBundle) {
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

        func list() -> [CleaningBundle] {
            var out: [CleaningBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningBundleStore() -> any CleaningBundleStore {
        return MemoryCleaningBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningBundleStore: CleaningBundleStore {
        var inner: MemoryCleaningBundleStore
        var cache: TTLCache<CleaningBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningBundleStore, cache: TTLCache<CleaningBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningBundle? {
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

        func save(_ item: CleaningBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningBundle] {
            return inner.list()
        }
    }

    static func newCachedCleaningBundleStore(_ inner: MemoryCleaningBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningBundleStore {
        return CachedCleaningBundleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning bundles. Empty fields match all.
    final class CleaningBundleQuery {
        var source: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minBudget: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningBundle) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningBundle]) -> [CleaningBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningBundles(_ store: any CleaningBundleStore, query: CleaningBundleQuery) -> [CleaningBundle] {
        return query.apply(store.list())
    }
}
