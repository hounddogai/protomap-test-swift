import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered authorization cycles by code.
    protocol TieredAuthorizationCycleStore {
        func find(_ code: String) -> TieredAuthorizationCycle?
        func save(_ item: TieredAuthorizationCycle)
        func remove(_ code: String) -> Bool
        func list() -> [TieredAuthorizationCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredAuthorizationCycleStore: TieredAuthorizationCycleStore {
        var items: [String: TieredAuthorizationCycle]
        var order: [String]

        init(items: [String: TieredAuthorizationCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredAuthorizationCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredAuthorizationCycle) {
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

        func list() -> [TieredAuthorizationCycle] {
            var out: [TieredAuthorizationCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredAuthorizationCycleStore() -> any TieredAuthorizationCycleStore {
        return MemoryTieredAuthorizationCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredAuthorizationCycleStore: TieredAuthorizationCycleStore {
        var inner: MemoryTieredAuthorizationCycleStore
        var cache: TTLCache<TieredAuthorizationCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredAuthorizationCycleStore, cache: TTLCache<TieredAuthorizationCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredAuthorizationCycle? {
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

        func save(_ item: TieredAuthorizationCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredAuthorizationCycle] {
            return inner.list()
        }
    }

    static func newCachedTieredAuthorizationCycleStore(_ inner: MemoryTieredAuthorizationCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredAuthorizationCycleStore {
        return CachedTieredAuthorizationCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered authorization cycles. Empty fields match all.
    final class TieredAuthorizationCycleQuery {
        var facility: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRevision: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredAuthorizationCycle) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredAuthorizationCycle]) -> [TieredAuthorizationCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredAuthorizationCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredAuthorizationCycles(_ store: any TieredAuthorizationCycleStore, query: TieredAuthorizationCycleQuery) -> [TieredAuthorizationCycle] {
        return query.apply(store.list())
    }
}
