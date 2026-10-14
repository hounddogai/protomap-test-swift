import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory cycles by code.
    protocol InventoryCycleStore {
        func find(_ code: String) -> InventoryCycle?
        func save(_ item: InventoryCycle)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryCycleStore: InventoryCycleStore {
        var items: [String: InventoryCycle]
        var order: [String]

        init(items: [String: InventoryCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryCycle) {
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

        func list() -> [InventoryCycle] {
            var out: [InventoryCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryCycleStore() -> any InventoryCycleStore {
        return MemoryInventoryCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryCycleStore: InventoryCycleStore {
        var inner: MemoryInventoryCycleStore
        var cache: TTLCache<InventoryCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryCycleStore, cache: TTLCache<InventoryCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryCycle? {
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

        func save(_ item: InventoryCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryCycle] {
            return inner.list()
        }
    }

    static func newCachedInventoryCycleStore(_ inner: MemoryInventoryCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryCycleStore {
        return CachedInventoryCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory cycles. Empty fields match all.
    final class InventoryCycleQuery {
        var title: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVersion: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryCycle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryCycle]) -> [InventoryCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryCycles(_ store: any InventoryCycleStore, query: InventoryCycleQuery) -> [InventoryCycle] {
        return query.apply(store.list())
    }
}
