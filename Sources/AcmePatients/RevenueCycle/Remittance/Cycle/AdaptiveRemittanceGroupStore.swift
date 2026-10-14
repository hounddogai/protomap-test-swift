import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive remittance groups by code.
    protocol AdaptiveRemittanceGroupStore {
        func find(_ code: String) -> AdaptiveRemittanceGroup?
        func save(_ item: AdaptiveRemittanceGroup)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveRemittanceGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveRemittanceGroupStore: AdaptiveRemittanceGroupStore {
        var items: [String: AdaptiveRemittanceGroup]
        var order: [String]

        init(items: [String: AdaptiveRemittanceGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveRemittanceGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveRemittanceGroup) {
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

        func list() -> [AdaptiveRemittanceGroup] {
            var out: [AdaptiveRemittanceGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveRemittanceGroupStore() -> any AdaptiveRemittanceGroupStore {
        return MemoryAdaptiveRemittanceGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveRemittanceGroupStore: AdaptiveRemittanceGroupStore {
        var inner: MemoryAdaptiveRemittanceGroupStore
        var cache: TTLCache<AdaptiveRemittanceGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveRemittanceGroupStore, cache: TTLCache<AdaptiveRemittanceGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveRemittanceGroup? {
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

        func save(_ item: AdaptiveRemittanceGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveRemittanceGroup] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveRemittanceGroupStore(_ inner: MemoryAdaptiveRemittanceGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveRemittanceGroupStore {
        return CachedAdaptiveRemittanceGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive remittance groups. Empty fields match all.
    final class AdaptiveRemittanceGroupQuery {
        var ward: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveRemittanceGroup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveRemittanceGroup]) -> [AdaptiveRemittanceGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveRemittanceGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveRemittanceGroups(_ store: any AdaptiveRemittanceGroupStore, query: AdaptiveRemittanceGroupQuery) -> [AdaptiveRemittanceGroup] {
        return query.apply(store.list())
    }
}
