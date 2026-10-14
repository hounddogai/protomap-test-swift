import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered read targets by code.
    protocol TieredReadTargetStore {
        func find(_ code: String) -> TieredReadTarget?
        func save(_ item: TieredReadTarget)
        func remove(_ code: String) -> Bool
        func list() -> [TieredReadTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredReadTargetStore: TieredReadTargetStore {
        var items: [String: TieredReadTarget]
        var order: [String]

        init(items: [String: TieredReadTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredReadTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredReadTarget) {
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

        func list() -> [TieredReadTarget] {
            var out: [TieredReadTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredReadTargetStore() -> any TieredReadTargetStore {
        return MemoryTieredReadTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredReadTargetStore: TieredReadTargetStore {
        var inner: MemoryTieredReadTargetStore
        var cache: TTLCache<TieredReadTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredReadTargetStore, cache: TTLCache<TieredReadTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredReadTarget? {
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

        func save(_ item: TieredReadTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredReadTarget] {
            return inner.list()
        }
    }

    static func newCachedTieredReadTargetStore(_ inner: MemoryTieredReadTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredReadTargetStore {
        return CachedTieredReadTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered read targets. Empty fields match all.
    final class TieredReadTargetQuery {
        var category: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMargin: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredReadTarget) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredReadTarget]) -> [TieredReadTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredReadTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredReadTargets(_ store: any TieredReadTargetStore, query: TieredReadTargetQuery) -> [TieredReadTarget] {
        return query.apply(store.list())
    }
}
