import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance slots by code.
    protocol RemittanceSlotStore {
        func find(_ code: String) -> RemittanceSlot?
        func save(_ item: RemittanceSlot)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceSlotStore: RemittanceSlotStore {
        var items: [String: RemittanceSlot]
        var order: [String]

        init(items: [String: RemittanceSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceSlot) {
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

        func list() -> [RemittanceSlot] {
            var out: [RemittanceSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceSlotStore() -> any RemittanceSlotStore {
        return MemoryRemittanceSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceSlotStore: RemittanceSlotStore {
        var inner: MemoryRemittanceSlotStore
        var cache: TTLCache<RemittanceSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceSlotStore, cache: TTLCache<RemittanceSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceSlot? {
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

        func save(_ item: RemittanceSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceSlot] {
            return inner.list()
        }
    }

    static func newCachedRemittanceSlotStore(_ inner: MemoryRemittanceSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceSlotStore {
        return CachedRemittanceSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance slots. Empty fields match all.
    final class RemittanceSlotQuery {
        var title: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minWeight: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceSlot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceSlot]) -> [RemittanceSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceSlots(_ store: any RemittanceSlotStore, query: RemittanceSlotQuery) -> [RemittanceSlot] {
        return query.apply(store.list())
    }
}
