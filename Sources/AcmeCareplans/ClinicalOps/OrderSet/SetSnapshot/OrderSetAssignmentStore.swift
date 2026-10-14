import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set assignments by code.
    protocol OrderSetAssignmentStore {
        func find(_ code: String) -> OrderSetAssignment?
        func save(_ item: OrderSetAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetAssignmentStore: OrderSetAssignmentStore {
        var items: [String: OrderSetAssignment]
        var order: [String]

        init(items: [String: OrderSetAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetAssignment) {
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

        func list() -> [OrderSetAssignment] {
            var out: [OrderSetAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetAssignmentStore() -> any OrderSetAssignmentStore {
        return MemoryOrderSetAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetAssignmentStore: OrderSetAssignmentStore {
        var inner: MemoryOrderSetAssignmentStore
        var cache: TTLCache<OrderSetAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetAssignmentStore, cache: TTLCache<OrderSetAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetAssignment? {
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

        func save(_ item: OrderSetAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetAssignment] {
            return inner.list()
        }
    }

    static func newCachedOrderSetAssignmentStore(_ inner: MemoryOrderSetAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetAssignmentStore {
        return CachedOrderSetAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set assignments. Empty fields match all.
    final class OrderSetAssignmentQuery {
        var locale: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetAssignment) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [OrderSetAssignment]) -> [OrderSetAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetAssignments(_ store: any OrderSetAssignmentStore, query: OrderSetAssignmentQuery) -> [OrderSetAssignment] {
        return query.apply(store.list())
    }
}
