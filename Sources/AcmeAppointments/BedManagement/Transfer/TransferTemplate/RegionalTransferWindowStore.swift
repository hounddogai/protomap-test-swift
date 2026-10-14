import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps regional transfer windows by code.
    protocol RegionalTransferWindowStore {
        func find(_ code: String) -> RegionalTransferWindow?
        func save(_ item: RegionalTransferWindow)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalTransferWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalTransferWindowStore: RegionalTransferWindowStore {
        var items: [String: RegionalTransferWindow]
        var order: [String]

        init(items: [String: RegionalTransferWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalTransferWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalTransferWindow) {
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

        func list() -> [RegionalTransferWindow] {
            var out: [RegionalTransferWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalTransferWindowStore() -> any RegionalTransferWindowStore {
        return MemoryRegionalTransferWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalTransferWindowStore: RegionalTransferWindowStore {
        var inner: MemoryRegionalTransferWindowStore
        var cache: TTLCache<RegionalTransferWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalTransferWindowStore, cache: TTLCache<RegionalTransferWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalTransferWindow? {
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

        func save(_ item: RegionalTransferWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalTransferWindow] {
            return inner.list()
        }
    }

    static func newCachedRegionalTransferWindowStore(_ inner: MemoryRegionalTransferWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalTransferWindowStore {
        return CachedRegionalTransferWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional transfer windows. Empty fields match all.
    final class RegionalTransferWindowQuery {
        var category: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minAmount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalTransferWindow) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalTransferWindow]) -> [RegionalTransferWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalTransferWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalTransferWindows(_ store: any RegionalTransferWindowStore, query: RegionalTransferWindowQuery) -> [RegionalTransferWindow] {
        return query.apply(store.list())
    }
}
