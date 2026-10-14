import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps fallback worklist groups by code.
    protocol FallbackWorklistGroupStore {
        func find(_ code: String) -> FallbackWorklistGroup?
        func save(_ item: FallbackWorklistGroup)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackWorklistGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackWorklistGroupStore: FallbackWorklistGroupStore {
        var items: [String: FallbackWorklistGroup]
        var order: [String]

        init(items: [String: FallbackWorklistGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackWorklistGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackWorklistGroup) {
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

        func list() -> [FallbackWorklistGroup] {
            var out: [FallbackWorklistGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackWorklistGroupStore() -> any FallbackWorklistGroupStore {
        return MemoryFallbackWorklistGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackWorklistGroupStore: FallbackWorklistGroupStore {
        var inner: MemoryFallbackWorklistGroupStore
        var cache: TTLCache<FallbackWorklistGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackWorklistGroupStore, cache: TTLCache<FallbackWorklistGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackWorklistGroup? {
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

        func save(_ item: FallbackWorklistGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackWorklistGroup] {
            return inner.list()
        }
    }

    static func newCachedFallbackWorklistGroupStore(_ inner: MemoryFallbackWorklistGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackWorklistGroupStore {
        return CachedFallbackWorklistGroupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback worklist groups. Empty fields match all.
    final class FallbackWorklistGroupQuery {
        var unit: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minSequence: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackWorklistGroup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackWorklistGroup]) -> [FallbackWorklistGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackWorklistGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackWorklistGroups(_ store: any FallbackWorklistGroupStore, query: FallbackWorklistGroupQuery) -> [FallbackWorklistGroup] {
        return query.apply(store.list())
    }
}
