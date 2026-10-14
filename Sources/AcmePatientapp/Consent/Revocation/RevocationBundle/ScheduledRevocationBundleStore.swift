import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled revocation bundles by code.
    protocol ScheduledRevocationBundleStore {
        func find(_ code: String) -> ScheduledRevocationBundle?
        func save(_ item: ScheduledRevocationBundle)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledRevocationBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledRevocationBundleStore: ScheduledRevocationBundleStore {
        var items: [String: ScheduledRevocationBundle]
        var order: [String]

        init(items: [String: ScheduledRevocationBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledRevocationBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledRevocationBundle) {
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

        func list() -> [ScheduledRevocationBundle] {
            var out: [ScheduledRevocationBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledRevocationBundleStore() -> any ScheduledRevocationBundleStore {
        return MemoryScheduledRevocationBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledRevocationBundleStore: ScheduledRevocationBundleStore {
        var inner: MemoryScheduledRevocationBundleStore
        var cache: TTLCache<ScheduledRevocationBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledRevocationBundleStore, cache: TTLCache<ScheduledRevocationBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledRevocationBundle? {
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

        func save(_ item: ScheduledRevocationBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledRevocationBundle] {
            return inner.list()
        }
    }

    static func newCachedScheduledRevocationBundleStore(_ inner: MemoryScheduledRevocationBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledRevocationBundleStore {
        return CachedScheduledRevocationBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled revocation bundles. Empty fields match all.
    final class ScheduledRevocationBundleQuery {
        var region: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledRevocationBundle) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledRevocationBundle]) -> [ScheduledRevocationBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledRevocationBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledRevocationBundles(_ store: any ScheduledRevocationBundleStore, query: ScheduledRevocationBundleQuery) -> [ScheduledRevocationBundle] {
        return query.apply(store.list())
    }
}
