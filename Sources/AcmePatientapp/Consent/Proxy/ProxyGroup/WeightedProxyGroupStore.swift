import AcmePlatform
import Foundation

extension Consent {
    /// Keeps weighted proxy groups by code.
    protocol WeightedProxyGroupStore {
        func find(_ code: String) -> WeightedProxyGroup?
        func save(_ item: WeightedProxyGroup)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedProxyGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedProxyGroupStore: WeightedProxyGroupStore {
        var items: [String: WeightedProxyGroup]
        var order: [String]

        init(items: [String: WeightedProxyGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedProxyGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedProxyGroup) {
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

        func list() -> [WeightedProxyGroup] {
            var out: [WeightedProxyGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedProxyGroupStore() -> any WeightedProxyGroupStore {
        return MemoryWeightedProxyGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedProxyGroupStore: WeightedProxyGroupStore {
        var inner: MemoryWeightedProxyGroupStore
        var cache: TTLCache<WeightedProxyGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedProxyGroupStore, cache: TTLCache<WeightedProxyGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedProxyGroup? {
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

        func save(_ item: WeightedProxyGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedProxyGroup] {
            return inner.list()
        }
    }

    static func newCachedWeightedProxyGroupStore(_ inner: MemoryWeightedProxyGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedProxyGroupStore {
        return CachedWeightedProxyGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted proxy groups. Empty fields match all.
    final class WeightedProxyGroupQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedProxyGroup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedProxyGroup]) -> [WeightedProxyGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedProxyGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedProxyGroups(_ store: any WeightedProxyGroupStore, query: WeightedProxyGroupQuery) -> [WeightedProxyGroup] {
        return query.apply(store.list())
    }
}
