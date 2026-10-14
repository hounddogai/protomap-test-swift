import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps rolling claim windows by code.
    protocol RollingClaimWindowStore {
        func find(_ code: String) -> RollingClaimWindow?
        func save(_ item: RollingClaimWindow)
        func remove(_ code: String) -> Bool
        func list() -> [RollingClaimWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingClaimWindowStore: RollingClaimWindowStore {
        var items: [String: RollingClaimWindow]
        var order: [String]

        init(items: [String: RollingClaimWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingClaimWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingClaimWindow) {
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

        func list() -> [RollingClaimWindow] {
            var out: [RollingClaimWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingClaimWindowStore() -> any RollingClaimWindowStore {
        return MemoryRollingClaimWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingClaimWindowStore: RollingClaimWindowStore {
        var inner: MemoryRollingClaimWindowStore
        var cache: TTLCache<RollingClaimWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingClaimWindowStore, cache: TTLCache<RollingClaimWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingClaimWindow? {
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

        func save(_ item: RollingClaimWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingClaimWindow] {
            return inner.list()
        }
    }

    static func newCachedRollingClaimWindowStore(_ inner: MemoryRollingClaimWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingClaimWindowStore {
        return CachedRollingClaimWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling claim windows. Empty fields match all.
    final class RollingClaimWindowQuery {
        var source: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingClaimWindow) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingClaimWindow]) -> [RollingClaimWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingClaimWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingClaimWindows(_ store: any RollingClaimWindowStore, query: RollingClaimWindowQuery) -> [RollingClaimWindow] {
        return query.apply(store.list())
    }
}
