import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps tiered shift bundles by code.
    protocol TieredShiftBundleStore {
        func find(_ code: String) -> TieredShiftBundle?
        func save(_ item: TieredShiftBundle)
        func remove(_ code: String) -> Bool
        func list() -> [TieredShiftBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredShiftBundleStore: TieredShiftBundleStore {
        var items: [String: TieredShiftBundle]
        var order: [String]

        init(items: [String: TieredShiftBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredShiftBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredShiftBundle) {
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

        func list() -> [TieredShiftBundle] {
            var out: [TieredShiftBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredShiftBundleStore() -> any TieredShiftBundleStore {
        return MemoryTieredShiftBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredShiftBundleStore: TieredShiftBundleStore {
        var inner: MemoryTieredShiftBundleStore
        var cache: TTLCache<TieredShiftBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredShiftBundleStore, cache: TTLCache<TieredShiftBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredShiftBundle? {
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

        func save(_ item: TieredShiftBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredShiftBundle] {
            return inner.list()
        }
    }

    static func newCachedTieredShiftBundleStore(_ inner: MemoryTieredShiftBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredShiftBundleStore {
        return CachedTieredShiftBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered shift bundles. Empty fields match all.
    final class TieredShiftBundleQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredShiftBundle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredShiftBundle]) -> [TieredShiftBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredShiftBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredShiftBundles(_ store: any TieredShiftBundleStore, query: TieredShiftBundleQuery) -> [TieredShiftBundle] {
        return query.apply(store.list())
    }
}
