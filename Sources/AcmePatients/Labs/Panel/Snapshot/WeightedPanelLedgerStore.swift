import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted panel ledgers by code.
    protocol WeightedPanelLedgerStore {
        func find(_ code: String) -> WeightedPanelLedger?
        func save(_ item: WeightedPanelLedger)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedPanelLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedPanelLedgerStore: WeightedPanelLedgerStore {
        var items: [String: WeightedPanelLedger]
        var order: [String]

        init(items: [String: WeightedPanelLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedPanelLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedPanelLedger) {
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

        func list() -> [WeightedPanelLedger] {
            var out: [WeightedPanelLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedPanelLedgerStore() -> any WeightedPanelLedgerStore {
        return MemoryWeightedPanelLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedPanelLedgerStore: WeightedPanelLedgerStore {
        var inner: MemoryWeightedPanelLedgerStore
        var cache: TTLCache<WeightedPanelLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedPanelLedgerStore, cache: TTLCache<WeightedPanelLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedPanelLedger? {
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

        func save(_ item: WeightedPanelLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedPanelLedger] {
            return inner.list()
        }
    }

    static func newCachedWeightedPanelLedgerStore(_ inner: MemoryWeightedPanelLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedPanelLedgerStore {
        return CachedWeightedPanelLedgerStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted panel ledgers. Empty fields match all.
    final class WeightedPanelLedgerQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedPanelLedger) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedPanelLedger]) -> [WeightedPanelLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedPanelLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedPanelLedgers(_ store: any WeightedPanelLedgerStore, query: WeightedPanelLedgerQuery) -> [WeightedPanelLedger] {
        return query.apply(store.list())
    }
}
