import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient outreach bundles by code.
    protocol LenientOutreachBundleStore {
        func find(_ code: String) -> LenientOutreachBundle?
        func save(_ item: LenientOutreachBundle)
        func remove(_ code: String) -> Bool
        func list() -> [LenientOutreachBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientOutreachBundleStore: LenientOutreachBundleStore {
        var items: [String: LenientOutreachBundle]
        var order: [String]

        init(items: [String: LenientOutreachBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientOutreachBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientOutreachBundle) {
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

        func list() -> [LenientOutreachBundle] {
            var out: [LenientOutreachBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientOutreachBundleStore() -> any LenientOutreachBundleStore {
        return MemoryLenientOutreachBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientOutreachBundleStore: LenientOutreachBundleStore {
        var inner: MemoryLenientOutreachBundleStore
        var cache: TTLCache<LenientOutreachBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientOutreachBundleStore, cache: TTLCache<LenientOutreachBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientOutreachBundle? {
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

        func save(_ item: LenientOutreachBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientOutreachBundle] {
            return inner.list()
        }
    }

    static func newCachedLenientOutreachBundleStore(_ inner: MemoryLenientOutreachBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientOutreachBundleStore {
        return CachedLenientOutreachBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient outreach bundles. Empty fields match all.
    final class LenientOutreachBundleQuery {
        var unit: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientOutreachBundle) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientOutreachBundle]) -> [LenientOutreachBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientOutreachBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientOutreachBundles(_ store: any LenientOutreachBundleStore, query: LenientOutreachBundleQuery) -> [LenientOutreachBundle] {
        return query.apply(store.list())
    }
}
