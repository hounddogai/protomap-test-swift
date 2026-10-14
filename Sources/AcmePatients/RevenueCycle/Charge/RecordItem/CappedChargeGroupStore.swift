import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped charge groups by code.
    protocol CappedChargeGroupStore {
        func find(_ code: String) -> CappedChargeGroup?
        func save(_ item: CappedChargeGroup)
        func remove(_ code: String) -> Bool
        func list() -> [CappedChargeGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedChargeGroupStore: CappedChargeGroupStore {
        var items: [String: CappedChargeGroup]
        var order: [String]

        init(items: [String: CappedChargeGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedChargeGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedChargeGroup) {
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

        func list() -> [CappedChargeGroup] {
            var out: [CappedChargeGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedChargeGroupStore() -> any CappedChargeGroupStore {
        return MemoryCappedChargeGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedChargeGroupStore: CappedChargeGroupStore {
        var inner: MemoryCappedChargeGroupStore
        var cache: TTLCache<CappedChargeGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedChargeGroupStore, cache: TTLCache<CappedChargeGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedChargeGroup? {
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

        func save(_ item: CappedChargeGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedChargeGroup] {
            return inner.list()
        }
    }

    static func newCachedCappedChargeGroupStore(_ inner: MemoryCappedChargeGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedChargeGroupStore {
        return CachedCappedChargeGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped charge groups. Empty fields match all.
    final class CappedChargeGroupQuery {
        var ward: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedChargeGroup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedChargeGroup]) -> [CappedChargeGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedChargeGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedChargeGroups(_ store: any CappedChargeGroupStore, query: CappedChargeGroupQuery) -> [CappedChargeGroup] {
        return query.apply(store.list())
    }
}
