import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps tiered order set cycles by code.
    protocol TieredOrderSetCycleStore {
        func find(_ code: String) -> TieredOrderSetCycle?
        func save(_ item: TieredOrderSetCycle)
        func remove(_ code: String) -> Bool
        func list() -> [TieredOrderSetCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredOrderSetCycleStore: TieredOrderSetCycleStore {
        var items: [String: TieredOrderSetCycle]
        var order: [String]

        init(items: [String: TieredOrderSetCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredOrderSetCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredOrderSetCycle) {
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

        func list() -> [TieredOrderSetCycle] {
            var out: [TieredOrderSetCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredOrderSetCycleStore() -> any TieredOrderSetCycleStore {
        return MemoryTieredOrderSetCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredOrderSetCycleStore: TieredOrderSetCycleStore {
        var inner: MemoryTieredOrderSetCycleStore
        var cache: TTLCache<TieredOrderSetCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredOrderSetCycleStore, cache: TTLCache<TieredOrderSetCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredOrderSetCycle? {
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

        func save(_ item: TieredOrderSetCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredOrderSetCycle] {
            return inner.list()
        }
    }

    static func newCachedTieredOrderSetCycleStore(_ inner: MemoryTieredOrderSetCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredOrderSetCycleStore {
        return CachedTieredOrderSetCycleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered order set cycles. Empty fields match all.
    final class TieredOrderSetCycleQuery {
        var category: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVersion: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredOrderSetCycle) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredOrderSetCycle]) -> [TieredOrderSetCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredOrderSetCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredOrderSetCycles(_ store: any TieredOrderSetCycleStore, query: TieredOrderSetCycleQuery) -> [TieredOrderSetCycle] {
        return query.apply(store.list())
    }
}
