import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps global study ledgers by code.
    protocol GlobalStudyLedgerStore {
        func find(_ code: String) -> GlobalStudyLedger?
        func save(_ item: GlobalStudyLedger)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalStudyLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalStudyLedgerStore: GlobalStudyLedgerStore {
        var items: [String: GlobalStudyLedger]
        var order: [String]

        init(items: [String: GlobalStudyLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalStudyLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalStudyLedger) {
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

        func list() -> [GlobalStudyLedger] {
            var out: [GlobalStudyLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalStudyLedgerStore() -> any GlobalStudyLedgerStore {
        return MemoryGlobalStudyLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalStudyLedgerStore: GlobalStudyLedgerStore {
        var inner: MemoryGlobalStudyLedgerStore
        var cache: TTLCache<GlobalStudyLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalStudyLedgerStore, cache: TTLCache<GlobalStudyLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalStudyLedger? {
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

        func save(_ item: GlobalStudyLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalStudyLedger] {
            return inner.list()
        }
    }

    static func newCachedGlobalStudyLedgerStore(_ inner: MemoryGlobalStudyLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalStudyLedgerStore {
        return CachedGlobalStudyLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global study ledgers. Empty fields match all.
    final class GlobalStudyLedgerQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalStudyLedger) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [GlobalStudyLedger]) -> [GlobalStudyLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalStudyLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalStudyLedgers(_ store: any GlobalStudyLedgerStore, query: GlobalStudyLedgerQuery) -> [GlobalStudyLedger] {
        return query.apply(store.list())
    }
}
