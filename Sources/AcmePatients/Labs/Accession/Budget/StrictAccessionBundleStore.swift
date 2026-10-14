import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict accession bundles by code.
    protocol StrictAccessionBundleStore {
        func find(_ code: String) -> StrictAccessionBundle?
        func save(_ item: StrictAccessionBundle)
        func remove(_ code: String) -> Bool
        func list() -> [StrictAccessionBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictAccessionBundleStore: StrictAccessionBundleStore {
        var items: [String: StrictAccessionBundle]
        var order: [String]

        init(items: [String: StrictAccessionBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictAccessionBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictAccessionBundle) {
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

        func list() -> [StrictAccessionBundle] {
            var out: [StrictAccessionBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictAccessionBundleStore() -> any StrictAccessionBundleStore {
        return MemoryStrictAccessionBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictAccessionBundleStore: StrictAccessionBundleStore {
        var inner: MemoryStrictAccessionBundleStore
        var cache: TTLCache<StrictAccessionBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictAccessionBundleStore, cache: TTLCache<StrictAccessionBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictAccessionBundle? {
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

        func save(_ item: StrictAccessionBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictAccessionBundle] {
            return inner.list()
        }
    }

    static func newCachedStrictAccessionBundleStore(_ inner: MemoryStrictAccessionBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictAccessionBundleStore {
        return CachedStrictAccessionBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict accession bundles. Empty fields match all.
    final class StrictAccessionBundleQuery {
        var locale: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictAccessionBundle) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictAccessionBundle]) -> [StrictAccessionBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictAccessionBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictAccessionBundles(_ store: any StrictAccessionBundleStore, query: StrictAccessionBundleQuery) -> [StrictAccessionBundle] {
        return query.apply(store.list())
    }
}
