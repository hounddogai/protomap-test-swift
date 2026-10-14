import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global specimen ledgers by code.
    protocol GlobalSpecimenLedgerStore {
        func find(_ code: String) -> GlobalSpecimenLedger?
        func save(_ item: GlobalSpecimenLedger)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalSpecimenLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalSpecimenLedgerStore: GlobalSpecimenLedgerStore {
        var items: [String: GlobalSpecimenLedger]
        var order: [String]

        init(items: [String: GlobalSpecimenLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalSpecimenLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalSpecimenLedger) {
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

        func list() -> [GlobalSpecimenLedger] {
            var out: [GlobalSpecimenLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalSpecimenLedgerStore() -> any GlobalSpecimenLedgerStore {
        return MemoryGlobalSpecimenLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalSpecimenLedgerStore: GlobalSpecimenLedgerStore {
        var inner: MemoryGlobalSpecimenLedgerStore
        var cache: TTLCache<GlobalSpecimenLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalSpecimenLedgerStore, cache: TTLCache<GlobalSpecimenLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalSpecimenLedger? {
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

        func save(_ item: GlobalSpecimenLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalSpecimenLedger] {
            return inner.list()
        }
    }

    static func newCachedGlobalSpecimenLedgerStore(_ inner: MemoryGlobalSpecimenLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalSpecimenLedgerStore {
        return CachedGlobalSpecimenLedgerStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global specimen ledgers. Empty fields match all.
    final class GlobalSpecimenLedgerQuery {
        var title: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalSpecimenLedger) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalSpecimenLedger]) -> [GlobalSpecimenLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalSpecimenLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalSpecimenLedgers(_ store: any GlobalSpecimenLedgerStore, query: GlobalSpecimenLedgerQuery) -> [GlobalSpecimenLedger] {
        return query.apply(store.list())
    }
}
