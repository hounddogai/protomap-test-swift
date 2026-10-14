import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps fallback modality groups by code.
    protocol FallbackModalityGroupStore {
        func find(_ code: String) -> FallbackModalityGroup?
        func save(_ item: FallbackModalityGroup)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackModalityGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackModalityGroupStore: FallbackModalityGroupStore {
        var items: [String: FallbackModalityGroup]
        var order: [String]

        init(items: [String: FallbackModalityGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackModalityGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackModalityGroup) {
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

        func list() -> [FallbackModalityGroup] {
            var out: [FallbackModalityGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackModalityGroupStore() -> any FallbackModalityGroupStore {
        return MemoryFallbackModalityGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackModalityGroupStore: FallbackModalityGroupStore {
        var inner: MemoryFallbackModalityGroupStore
        var cache: TTLCache<FallbackModalityGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackModalityGroupStore, cache: TTLCache<FallbackModalityGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackModalityGroup? {
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

        func save(_ item: FallbackModalityGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackModalityGroup] {
            return inner.list()
        }
    }

    static func newCachedFallbackModalityGroupStore(_ inner: MemoryFallbackModalityGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackModalityGroupStore {
        return CachedFallbackModalityGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback modality groups. Empty fields match all.
    final class FallbackModalityGroupQuery {
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

        func matches(_ item: FallbackModalityGroup) -> Bool {
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

        func apply(_ items: [FallbackModalityGroup]) -> [FallbackModalityGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackModalityGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackModalityGroups(_ store: any FallbackModalityGroupStore, query: FallbackModalityGroupQuery) -> [FallbackModalityGroup] {
        return query.apply(store.list())
    }
}
