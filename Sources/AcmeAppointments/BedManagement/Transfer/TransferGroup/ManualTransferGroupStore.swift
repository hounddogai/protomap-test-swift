import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual transfer groups by code.
    protocol ManualTransferGroupStore {
        func find(_ code: String) -> ManualTransferGroup?
        func save(_ item: ManualTransferGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ManualTransferGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualTransferGroupStore: ManualTransferGroupStore {
        var items: [String: ManualTransferGroup]
        var order: [String]

        init(items: [String: ManualTransferGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualTransferGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualTransferGroup) {
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

        func list() -> [ManualTransferGroup] {
            var out: [ManualTransferGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualTransferGroupStore() -> any ManualTransferGroupStore {
        return MemoryManualTransferGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualTransferGroupStore: ManualTransferGroupStore {
        var inner: MemoryManualTransferGroupStore
        var cache: TTLCache<ManualTransferGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualTransferGroupStore, cache: TTLCache<ManualTransferGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualTransferGroup? {
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

        func save(_ item: ManualTransferGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualTransferGroup] {
            return inner.list()
        }
    }

    static func newCachedManualTransferGroupStore(_ inner: MemoryManualTransferGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualTransferGroupStore {
        return CachedManualTransferGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual transfer groups. Empty fields match all.
    final class ManualTransferGroupQuery {
        var unit: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualTransferGroup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [ManualTransferGroup]) -> [ManualTransferGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualTransferGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualTransferGroups(_ store: any ManualTransferGroupStore, query: ManualTransferGroupQuery) -> [ManualTransferGroup] {
        return query.apply(store.list())
    }
}
