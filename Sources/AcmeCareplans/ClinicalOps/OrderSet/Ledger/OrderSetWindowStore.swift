import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set windows by code.
    protocol OrderSetWindowStore {
        func find(_ code: String) -> OrderSetWindow?
        func save(_ item: OrderSetWindow)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetWindowStore: OrderSetWindowStore {
        var items: [String: OrderSetWindow]
        var order: [String]

        init(items: [String: OrderSetWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetWindow) {
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

        func list() -> [OrderSetWindow] {
            var out: [OrderSetWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetWindowStore() -> any OrderSetWindowStore {
        return MemoryOrderSetWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetWindowStore: OrderSetWindowStore {
        var inner: MemoryOrderSetWindowStore
        var cache: TTLCache<OrderSetWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetWindowStore, cache: TTLCache<OrderSetWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetWindow? {
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

        func save(_ item: OrderSetWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetWindow] {
            return inner.list()
        }
    }

    static func newCachedOrderSetWindowStore(_ inner: MemoryOrderSetWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetWindowStore {
        return CachedOrderSetWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set windows. Empty fields match all.
    final class OrderSetWindowQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetWindow]) -> [OrderSetWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetWindows(_ store: any OrderSetWindowStore, query: OrderSetWindowQuery) -> [OrderSetWindow] {
        return query.apply(store.list())
    }
}
