import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps tiered isolation groups by code.
    protocol TieredIsolationGroupStore {
        func find(_ code: String) -> TieredIsolationGroup?
        func save(_ item: TieredIsolationGroup)
        func remove(_ code: String) -> Bool
        func list() -> [TieredIsolationGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredIsolationGroupStore: TieredIsolationGroupStore {
        var items: [String: TieredIsolationGroup]
        var order: [String]

        init(items: [String: TieredIsolationGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredIsolationGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredIsolationGroup) {
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

        func list() -> [TieredIsolationGroup] {
            var out: [TieredIsolationGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredIsolationGroupStore() -> any TieredIsolationGroupStore {
        return MemoryTieredIsolationGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredIsolationGroupStore: TieredIsolationGroupStore {
        var inner: MemoryTieredIsolationGroupStore
        var cache: TTLCache<TieredIsolationGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredIsolationGroupStore, cache: TTLCache<TieredIsolationGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredIsolationGroup? {
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

        func save(_ item: TieredIsolationGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredIsolationGroup] {
            return inner.list()
        }
    }

    static func newCachedTieredIsolationGroupStore(_ inner: MemoryTieredIsolationGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredIsolationGroupStore {
        return CachedTieredIsolationGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered isolation groups. Empty fields match all.
    final class TieredIsolationGroupQuery {
        var segment: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minPriority: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredIsolationGroup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [TieredIsolationGroup]) -> [TieredIsolationGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredIsolationGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredIsolationGroups(_ store: any TieredIsolationGroupStore, query: TieredIsolationGroupQuery) -> [TieredIsolationGroup] {
        return query.apply(store.list())
    }
}
