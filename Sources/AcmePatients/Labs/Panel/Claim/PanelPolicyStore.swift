import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel policies by code.
    protocol PanelPolicyStore {
        func find(_ code: String) -> PanelPolicy?
        func save(_ item: PanelPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [PanelPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelPolicyStore: PanelPolicyStore {
        var items: [String: PanelPolicy]
        var order: [String]

        init(items: [String: PanelPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelPolicy) {
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

        func list() -> [PanelPolicy] {
            var out: [PanelPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelPolicyStore() -> any PanelPolicyStore {
        return MemoryPanelPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelPolicyStore: PanelPolicyStore {
        var inner: MemoryPanelPolicyStore
        var cache: TTLCache<PanelPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelPolicyStore, cache: TTLCache<PanelPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelPolicy? {
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

        func save(_ item: PanelPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelPolicy] {
            return inner.list()
        }
    }

    static func newCachedPanelPolicyStore(_ inner: MemoryPanelPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelPolicyStore {
        return CachedPanelPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel policies. Empty fields match all.
    final class PanelPolicyQuery {
        var title: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelPolicy) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelPolicy]) -> [PanelPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelPolicies(_ store: any PanelPolicyStore, query: PanelPolicyQuery) -> [PanelPolicy] {
        return query.apply(store.list())
    }
}
