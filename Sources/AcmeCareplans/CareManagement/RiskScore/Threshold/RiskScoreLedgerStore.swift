import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score ledgers by code.
    protocol RiskScoreLedgerStore {
        func find(_ code: String) -> RiskScoreLedger?
        func save(_ item: RiskScoreLedger)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreLedgerStore: RiskScoreLedgerStore {
        var items: [String: RiskScoreLedger]
        var order: [String]

        init(items: [String: RiskScoreLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreLedger) {
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

        func list() -> [RiskScoreLedger] {
            var out: [RiskScoreLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreLedgerStore() -> any RiskScoreLedgerStore {
        return MemoryRiskScoreLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreLedgerStore: RiskScoreLedgerStore {
        var inner: MemoryRiskScoreLedgerStore
        var cache: TTLCache<RiskScoreLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreLedgerStore, cache: TTLCache<RiskScoreLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreLedger? {
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

        func save(_ item: RiskScoreLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreLedger] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreLedgerStore(_ inner: MemoryRiskScoreLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreLedgerStore {
        return CachedRiskScoreLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score ledgers. Empty fields match all.
    final class RiskScoreLedgerQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreLedger) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreLedger]) -> [RiskScoreLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreLedgers(_ store: any RiskScoreLedgerStore, query: RiskScoreLedgerQuery) -> [RiskScoreLedger] {
        return query.apply(store.list())
    }
}
