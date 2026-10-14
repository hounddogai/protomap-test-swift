import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive network cycles by code.
    protocol AdaptiveNetworkCycleStore {
        func find(_ code: String) -> AdaptiveNetworkCycle?
        func save(_ item: AdaptiveNetworkCycle)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveNetworkCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveNetworkCycleStore: AdaptiveNetworkCycleStore {
        var items: [String: AdaptiveNetworkCycle]
        var order: [String]

        init(items: [String: AdaptiveNetworkCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveNetworkCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveNetworkCycle) {
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

        func list() -> [AdaptiveNetworkCycle] {
            var out: [AdaptiveNetworkCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveNetworkCycleStore() -> any AdaptiveNetworkCycleStore {
        return MemoryAdaptiveNetworkCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveNetworkCycleStore: AdaptiveNetworkCycleStore {
        var inner: MemoryAdaptiveNetworkCycleStore
        var cache: TTLCache<AdaptiveNetworkCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveNetworkCycleStore, cache: TTLCache<AdaptiveNetworkCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveNetworkCycle? {
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

        func save(_ item: AdaptiveNetworkCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveNetworkCycle] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveNetworkCycleStore(_ inner: MemoryAdaptiveNetworkCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveNetworkCycleStore {
        return CachedAdaptiveNetworkCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive network cycles. Empty fields match all.
    final class AdaptiveNetworkCycleQuery {
        var label: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveNetworkCycle) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveNetworkCycle]) -> [AdaptiveNetworkCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveNetworkCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveNetworkCycles(_ store: any AdaptiveNetworkCycleStore, query: AdaptiveNetworkCycleQuery) -> [AdaptiveNetworkCycle] {
        return query.apply(store.list())
    }
}
