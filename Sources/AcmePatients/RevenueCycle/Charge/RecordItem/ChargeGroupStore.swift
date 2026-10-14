import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge groups by code.
    protocol ChargeGroupStore {
        func find(_ code: String) -> ChargeGroup?
        func save(_ item: ChargeGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeGroupStore: ChargeGroupStore {
        var items: [String: ChargeGroup]
        var order: [String]

        init(items: [String: ChargeGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeGroup) {
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

        func list() -> [ChargeGroup] {
            var out: [ChargeGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeGroupStore() -> any ChargeGroupStore {
        return MemoryChargeGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeGroupStore: ChargeGroupStore {
        var inner: MemoryChargeGroupStore
        var cache: TTLCache<ChargeGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeGroupStore, cache: TTLCache<ChargeGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeGroup? {
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

        func save(_ item: ChargeGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeGroup] {
            return inner.list()
        }
    }

    static func newCachedChargeGroupStore(_ inner: MemoryChargeGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeGroupStore {
        return CachedChargeGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge groups. Empty fields match all.
    final class ChargeGroupQuery {
        var source: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeGroup) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeGroup]) -> [ChargeGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeGroups(_ store: any ChargeGroupStore, query: ChargeGroupQuery) -> [ChargeGroup] {
        return query.apply(store.list())
    }
}
