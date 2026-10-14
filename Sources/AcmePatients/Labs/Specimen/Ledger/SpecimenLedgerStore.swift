import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen ledgers by code.
    protocol SpecimenLedgerStore {
        func find(_ code: String) -> SpecimenLedger?
        func save(_ item: SpecimenLedger)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenLedgerStore: SpecimenLedgerStore {
        var items: [String: SpecimenLedger]
        var order: [String]

        init(items: [String: SpecimenLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenLedger) {
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

        func list() -> [SpecimenLedger] {
            var out: [SpecimenLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenLedgerStore() -> any SpecimenLedgerStore {
        return MemorySpecimenLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenLedgerStore: SpecimenLedgerStore {
        var inner: MemorySpecimenLedgerStore
        var cache: TTLCache<SpecimenLedger>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenLedgerStore, cache: TTLCache<SpecimenLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenLedger? {
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

        func save(_ item: SpecimenLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenLedger] {
            return inner.list()
        }
    }

    static func newCachedSpecimenLedgerStore(_ inner: MemorySpecimenLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenLedgerStore {
        return CachedSpecimenLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen ledgers. Empty fields match all.
    final class SpecimenLedgerQuery {
        var segment: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenLedger) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenLedger]) -> [SpecimenLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenLedgers(_ store: any SpecimenLedgerStore, query: SpecimenLedgerQuery) -> [SpecimenLedger] {
        return query.apply(store.list())
    }
}
