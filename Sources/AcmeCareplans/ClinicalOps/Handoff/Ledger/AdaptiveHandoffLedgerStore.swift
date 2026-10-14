import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps adaptive handoff ledgers by code.
    protocol AdaptiveHandoffLedgerStore {
        func find(_ code: String) -> AdaptiveHandoffLedger?
        func save(_ item: AdaptiveHandoffLedger)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveHandoffLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveHandoffLedgerStore: AdaptiveHandoffLedgerStore {
        var items: [String: AdaptiveHandoffLedger]
        var order: [String]

        init(items: [String: AdaptiveHandoffLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveHandoffLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveHandoffLedger) {
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

        func list() -> [AdaptiveHandoffLedger] {
            var out: [AdaptiveHandoffLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveHandoffLedgerStore() -> any AdaptiveHandoffLedgerStore {
        return MemoryAdaptiveHandoffLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveHandoffLedgerStore: AdaptiveHandoffLedgerStore {
        var inner: MemoryAdaptiveHandoffLedgerStore
        var cache: TTLCache<AdaptiveHandoffLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveHandoffLedgerStore, cache: TTLCache<AdaptiveHandoffLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveHandoffLedger? {
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

        func save(_ item: AdaptiveHandoffLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveHandoffLedger] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveHandoffLedgerStore(_ inner: MemoryAdaptiveHandoffLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveHandoffLedgerStore {
        return CachedAdaptiveHandoffLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive handoff ledgers. Empty fields match all.
    final class AdaptiveHandoffLedgerQuery {
        var unit: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveHandoffLedger) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveHandoffLedger]) -> [AdaptiveHandoffLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveHandoffLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveHandoffLedgers(_ store: any AdaptiveHandoffLedgerStore, query: AdaptiveHandoffLedgerQuery) -> [AdaptiveHandoffLedger] {
        return query.apply(store.list())
    }
}
