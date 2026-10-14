import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global risk score ledgers by code.
    protocol GlobalRiskScoreLedgerStore {
        func find(_ code: String) -> GlobalRiskScoreLedger?
        func save(_ item: GlobalRiskScoreLedger)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalRiskScoreLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalRiskScoreLedgerStore: GlobalRiskScoreLedgerStore {
        var items: [String: GlobalRiskScoreLedger]
        var order: [String]

        init(items: [String: GlobalRiskScoreLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalRiskScoreLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalRiskScoreLedger) {
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

        func list() -> [GlobalRiskScoreLedger] {
            var out: [GlobalRiskScoreLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalRiskScoreLedgerStore() -> any GlobalRiskScoreLedgerStore {
        return MemoryGlobalRiskScoreLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalRiskScoreLedgerStore: GlobalRiskScoreLedgerStore {
        var inner: MemoryGlobalRiskScoreLedgerStore
        var cache: TTLCache<GlobalRiskScoreLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalRiskScoreLedgerStore, cache: TTLCache<GlobalRiskScoreLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalRiskScoreLedger? {
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

        func save(_ item: GlobalRiskScoreLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalRiskScoreLedger] {
            return inner.list()
        }
    }

    static func newCachedGlobalRiskScoreLedgerStore(_ inner: MemoryGlobalRiskScoreLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalRiskScoreLedgerStore {
        return CachedGlobalRiskScoreLedgerStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global risk score ledgers. Empty fields match all.
    final class GlobalRiskScoreLedgerQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalRiskScoreLedger) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalRiskScoreLedger]) -> [GlobalRiskScoreLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalRiskScoreLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalRiskScoreLedgers(_ store: any GlobalRiskScoreLedgerStore, query: GlobalRiskScoreLedgerQuery) -> [GlobalRiskScoreLedger] {
        return query.apply(store.list())
    }
}
