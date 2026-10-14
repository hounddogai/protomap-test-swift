import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered read overrides by code.
    protocol TieredReadOverrideStore {
        func find(_ code: String) -> TieredReadOverride?
        func save(_ item: TieredReadOverride)
        func remove(_ code: String) -> Bool
        func list() -> [TieredReadOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredReadOverrideStore: TieredReadOverrideStore {
        var items: [String: TieredReadOverride]
        var order: [String]

        init(items: [String: TieredReadOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredReadOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredReadOverride) {
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

        func list() -> [TieredReadOverride] {
            var out: [TieredReadOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredReadOverrideStore() -> any TieredReadOverrideStore {
        return MemoryTieredReadOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredReadOverrideStore: TieredReadOverrideStore {
        var inner: MemoryTieredReadOverrideStore
        var cache: TTLCache<TieredReadOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredReadOverrideStore, cache: TTLCache<TieredReadOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredReadOverride? {
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

        func save(_ item: TieredReadOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredReadOverride] {
            return inner.list()
        }
    }

    static func newCachedTieredReadOverrideStore(_ inner: MemoryTieredReadOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredReadOverrideStore {
        return CachedTieredReadOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered read overrides. Empty fields match all.
    final class TieredReadOverrideQuery {
        var unit: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minPriority: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredReadOverride) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredReadOverride]) -> [TieredReadOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredReadOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredReadOverrides(_ store: any TieredReadOverrideStore, query: TieredReadOverrideQuery) -> [TieredReadOverride] {
        return query.apply(store.list())
    }
}
