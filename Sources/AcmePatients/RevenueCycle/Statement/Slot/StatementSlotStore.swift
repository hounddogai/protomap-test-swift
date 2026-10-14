import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement slots by code.
    protocol StatementSlotStore {
        func find(_ code: String) -> StatementSlot?
        func save(_ item: StatementSlot)
        func remove(_ code: String) -> Bool
        func list() -> [StatementSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementSlotStore: StatementSlotStore {
        var items: [String: StatementSlot]
        var order: [String]

        init(items: [String: StatementSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementSlot) {
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

        func list() -> [StatementSlot] {
            var out: [StatementSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementSlotStore() -> any StatementSlotStore {
        return MemoryStatementSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementSlotStore: StatementSlotStore {
        var inner: MemoryStatementSlotStore
        var cache: TTLCache<StatementSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementSlotStore, cache: TTLCache<StatementSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementSlot? {
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

        func save(_ item: StatementSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementSlot] {
            return inner.list()
        }
    }

    static func newCachedStatementSlotStore(_ inner: MemoryStatementSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementSlotStore {
        return CachedStatementSlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement slots. Empty fields match all.
    final class StatementSlotQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementSlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementSlot]) -> [StatementSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementSlots(_ store: any StatementSlotStore, query: StatementSlotQuery) -> [StatementSlot] {
        return query.apply(store.list())
    }
}
