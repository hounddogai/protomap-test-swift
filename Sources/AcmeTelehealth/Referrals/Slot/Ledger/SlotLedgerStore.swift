import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot ledgers by code.
    protocol SlotLedgerStore {
        func find(_ code: String) -> SlotLedger?
        func save(_ item: SlotLedger)
        func remove(_ code: String) -> Bool
        func list() -> [SlotLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotLedgerStore: SlotLedgerStore {
        var items: [String: SlotLedger]
        var order: [String]

        init(items: [String: SlotLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotLedger) {
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

        func list() -> [SlotLedger] {
            var out: [SlotLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotLedgerStore() -> any SlotLedgerStore {
        return MemorySlotLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotLedgerStore: SlotLedgerStore {
        var inner: MemorySlotLedgerStore
        var cache: TTLCache<SlotLedger>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotLedgerStore, cache: TTLCache<SlotLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotLedger? {
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

        func save(_ item: SlotLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotLedger] {
            return inner.list()
        }
    }

    static func newCachedSlotLedgerStore(_ inner: MemorySlotLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotLedgerStore {
        return CachedSlotLedgerStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot ledgers. Empty fields match all.
    final class SlotLedgerQuery {
        var source: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotLedger) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [SlotLedger]) -> [SlotLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotLedgers(_ store: any SlotLedgerStore, query: SlotLedgerQuery) -> [SlotLedger] {
        return query.apply(store.list())
    }
}
