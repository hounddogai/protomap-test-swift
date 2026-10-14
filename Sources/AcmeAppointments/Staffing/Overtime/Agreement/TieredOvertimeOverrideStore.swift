import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps tiered overtime overrides by code.
    protocol TieredOvertimeOverrideStore {
        func find(_ code: String) -> TieredOvertimeOverride?
        func save(_ item: TieredOvertimeOverride)
        func remove(_ code: String) -> Bool
        func list() -> [TieredOvertimeOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredOvertimeOverrideStore: TieredOvertimeOverrideStore {
        var items: [String: TieredOvertimeOverride]
        var order: [String]

        init(items: [String: TieredOvertimeOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredOvertimeOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredOvertimeOverride) {
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

        func list() -> [TieredOvertimeOverride] {
            var out: [TieredOvertimeOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredOvertimeOverrideStore() -> any TieredOvertimeOverrideStore {
        return MemoryTieredOvertimeOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredOvertimeOverrideStore: TieredOvertimeOverrideStore {
        var inner: MemoryTieredOvertimeOverrideStore
        var cache: TTLCache<TieredOvertimeOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredOvertimeOverrideStore, cache: TTLCache<TieredOvertimeOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredOvertimeOverride? {
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

        func save(_ item: TieredOvertimeOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredOvertimeOverride] {
            return inner.list()
        }
    }

    static func newCachedTieredOvertimeOverrideStore(_ inner: MemoryTieredOvertimeOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredOvertimeOverrideStore {
        return CachedTieredOvertimeOverrideStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered overtime overrides. Empty fields match all.
    final class TieredOvertimeOverrideQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredOvertimeOverride) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [TieredOvertimeOverride]) -> [TieredOvertimeOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredOvertimeOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredOvertimeOverrides(_ store: any TieredOvertimeOverrideStore, query: TieredOvertimeOverrideQuery) -> [TieredOvertimeOverride] {
        return query.apply(store.list())
    }
}
