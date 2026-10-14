import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps tiered task overrides by code.
    protocol TieredTaskOverrideStore {
        func find(_ code: String) -> TieredTaskOverride?
        func save(_ item: TieredTaskOverride)
        func remove(_ code: String) -> Bool
        func list() -> [TieredTaskOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredTaskOverrideStore: TieredTaskOverrideStore {
        var items: [String: TieredTaskOverride]
        var order: [String]

        init(items: [String: TieredTaskOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredTaskOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredTaskOverride) {
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

        func list() -> [TieredTaskOverride] {
            var out: [TieredTaskOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredTaskOverrideStore() -> any TieredTaskOverrideStore {
        return MemoryTieredTaskOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredTaskOverrideStore: TieredTaskOverrideStore {
        var inner: MemoryTieredTaskOverrideStore
        var cache: TTLCache<TieredTaskOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredTaskOverrideStore, cache: TTLCache<TieredTaskOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredTaskOverride? {
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

        func save(_ item: TieredTaskOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredTaskOverride] {
            return inner.list()
        }
    }

    static func newCachedTieredTaskOverrideStore(_ inner: MemoryTieredTaskOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredTaskOverrideStore {
        return CachedTieredTaskOverrideStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered task overrides. Empty fields match all.
    final class TieredTaskOverrideQuery {
        var locale: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredTaskOverride) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredTaskOverride]) -> [TieredTaskOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredTaskOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredTaskOverrides(_ store: any TieredTaskOverrideStore, query: TieredTaskOverrideQuery) -> [TieredTaskOverride] {
        return query.apply(store.list())
    }
}
