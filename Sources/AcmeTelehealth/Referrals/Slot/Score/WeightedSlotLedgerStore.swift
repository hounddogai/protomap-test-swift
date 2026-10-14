import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted slot ledgers by code.
    protocol WeightedSlotLedgerStore {
        func find(_ code: String) -> WeightedSlotLedger?
        func save(_ item: WeightedSlotLedger)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSlotLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSlotLedgerStore: WeightedSlotLedgerStore {
        var items: [String: WeightedSlotLedger]
        var order: [String]

        init(items: [String: WeightedSlotLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSlotLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSlotLedger) {
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

        func list() -> [WeightedSlotLedger] {
            var out: [WeightedSlotLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSlotLedgerStore() -> any WeightedSlotLedgerStore {
        return MemoryWeightedSlotLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSlotLedgerStore: WeightedSlotLedgerStore {
        var inner: MemoryWeightedSlotLedgerStore
        var cache: TTLCache<WeightedSlotLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSlotLedgerStore, cache: TTLCache<WeightedSlotLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSlotLedger? {
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

        func save(_ item: WeightedSlotLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSlotLedger] {
            return inner.list()
        }
    }

    static func newCachedWeightedSlotLedgerStore(_ inner: MemoryWeightedSlotLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSlotLedgerStore {
        return CachedWeightedSlotLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted slot ledgers. Empty fields match all.
    final class WeightedSlotLedgerQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSlotLedger) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedSlotLedger]) -> [WeightedSlotLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSlotLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSlotLedgers(_ store: any WeightedSlotLedgerStore, query: WeightedSlotLedgerQuery) -> [WeightedSlotLedger] {
        return query.apply(store.list())
    }
}
