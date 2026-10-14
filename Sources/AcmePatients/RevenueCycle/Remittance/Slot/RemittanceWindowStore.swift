import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance windows by code.
    protocol RemittanceWindowStore {
        func find(_ code: String) -> RemittanceWindow?
        func save(_ item: RemittanceWindow)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceWindowStore: RemittanceWindowStore {
        var items: [String: RemittanceWindow]
        var order: [String]

        init(items: [String: RemittanceWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceWindow) {
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

        func list() -> [RemittanceWindow] {
            var out: [RemittanceWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceWindowStore() -> any RemittanceWindowStore {
        return MemoryRemittanceWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceWindowStore: RemittanceWindowStore {
        var inner: MemoryRemittanceWindowStore
        var cache: TTLCache<RemittanceWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceWindowStore, cache: TTLCache<RemittanceWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceWindow? {
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

        func save(_ item: RemittanceWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceWindow] {
            return inner.list()
        }
    }

    static func newCachedRemittanceWindowStore(_ inner: MemoryRemittanceWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceWindowStore {
        return CachedRemittanceWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance windows. Empty fields match all.
    final class RemittanceWindowQuery {
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

        func matches(_ item: RemittanceWindow) -> Bool {
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

        func apply(_ items: [RemittanceWindow]) -> [RemittanceWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceWindows(_ store: any RemittanceWindowStore, query: RemittanceWindowQuery) -> [RemittanceWindow] {
        return query.apply(store.list())
    }
}
