import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps weighted transfer groups by code.
    protocol WeightedTransferGroupStore {
        func find(_ code: String) -> WeightedTransferGroup?
        func save(_ item: WeightedTransferGroup)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedTransferGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedTransferGroupStore: WeightedTransferGroupStore {
        var items: [String: WeightedTransferGroup]
        var order: [String]

        init(items: [String: WeightedTransferGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedTransferGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedTransferGroup) {
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

        func list() -> [WeightedTransferGroup] {
            var out: [WeightedTransferGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedTransferGroupStore() -> any WeightedTransferGroupStore {
        return MemoryWeightedTransferGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedTransferGroupStore: WeightedTransferGroupStore {
        var inner: MemoryWeightedTransferGroupStore
        var cache: TTLCache<WeightedTransferGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedTransferGroupStore, cache: TTLCache<WeightedTransferGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedTransferGroup? {
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

        func save(_ item: WeightedTransferGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedTransferGroup] {
            return inner.list()
        }
    }

    static func newCachedWeightedTransferGroupStore(_ inner: MemoryWeightedTransferGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedTransferGroupStore {
        return CachedWeightedTransferGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted transfer groups. Empty fields match all.
    final class WeightedTransferGroupQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedTransferGroup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedTransferGroup]) -> [WeightedTransferGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedTransferGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedTransferGroups(_ store: any WeightedTransferGroupStore, query: WeightedTransferGroupQuery) -> [WeightedTransferGroup] {
        return query.apply(store.list())
    }
}
