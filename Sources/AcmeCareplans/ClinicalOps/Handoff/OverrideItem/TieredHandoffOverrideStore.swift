import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps tiered handoff overrides by code.
    protocol TieredHandoffOverrideStore {
        func find(_ code: String) -> TieredHandoffOverride?
        func save(_ item: TieredHandoffOverride)
        func remove(_ code: String) -> Bool
        func list() -> [TieredHandoffOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredHandoffOverrideStore: TieredHandoffOverrideStore {
        var items: [String: TieredHandoffOverride]
        var order: [String]

        init(items: [String: TieredHandoffOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredHandoffOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredHandoffOverride) {
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

        func list() -> [TieredHandoffOverride] {
            var out: [TieredHandoffOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredHandoffOverrideStore() -> any TieredHandoffOverrideStore {
        return MemoryTieredHandoffOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredHandoffOverrideStore: TieredHandoffOverrideStore {
        var inner: MemoryTieredHandoffOverrideStore
        var cache: TTLCache<TieredHandoffOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredHandoffOverrideStore, cache: TTLCache<TieredHandoffOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredHandoffOverride? {
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

        func save(_ item: TieredHandoffOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredHandoffOverride] {
            return inner.list()
        }
    }

    static func newCachedTieredHandoffOverrideStore(_ inner: MemoryTieredHandoffOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredHandoffOverrideStore {
        return CachedTieredHandoffOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered handoff overrides. Empty fields match all.
    final class TieredHandoffOverrideQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredHandoffOverride) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredHandoffOverride]) -> [TieredHandoffOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredHandoffOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredHandoffOverrides(_ store: any TieredHandoffOverrideStore, query: TieredHandoffOverrideQuery) -> [TieredHandoffOverride] {
        return query.apply(store.list())
    }
}
