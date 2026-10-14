import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps rolling remittance entries by code.
    protocol RollingRemittanceEntryStore {
        func find(_ code: String) -> RollingRemittanceEntry?
        func save(_ item: RollingRemittanceEntry)
        func remove(_ code: String) -> Bool
        func list() -> [RollingRemittanceEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingRemittanceEntryStore: RollingRemittanceEntryStore {
        var items: [String: RollingRemittanceEntry]
        var order: [String]

        init(items: [String: RollingRemittanceEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingRemittanceEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingRemittanceEntry) {
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

        func list() -> [RollingRemittanceEntry] {
            var out: [RollingRemittanceEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingRemittanceEntryStore() -> any RollingRemittanceEntryStore {
        return MemoryRollingRemittanceEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingRemittanceEntryStore: RollingRemittanceEntryStore {
        var inner: MemoryRollingRemittanceEntryStore
        var cache: TTLCache<RollingRemittanceEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingRemittanceEntryStore, cache: TTLCache<RollingRemittanceEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingRemittanceEntry? {
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

        func save(_ item: RollingRemittanceEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingRemittanceEntry] {
            return inner.list()
        }
    }

    static func newCachedRollingRemittanceEntryStore(_ inner: MemoryRollingRemittanceEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingRemittanceEntryStore {
        return CachedRollingRemittanceEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling remittance entries. Empty fields match all.
    final class RollingRemittanceEntryQuery {
        var category: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingRemittanceEntry) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [RollingRemittanceEntry]) -> [RollingRemittanceEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingRemittanceEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingRemittanceEntries(_ store: any RollingRemittanceEntryStore, query: RollingRemittanceEntryQuery) -> [RollingRemittanceEntry] {
        return query.apply(store.list())
    }
}
