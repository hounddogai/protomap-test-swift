import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution ledgers by code.
    protocol SubstitutionLedgerStore {
        func find(_ code: String) -> SubstitutionLedger?
        func save(_ item: SubstitutionLedger)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionLedgerStore: SubstitutionLedgerStore {
        var items: [String: SubstitutionLedger]
        var order: [String]

        init(items: [String: SubstitutionLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionLedger) {
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

        func list() -> [SubstitutionLedger] {
            var out: [SubstitutionLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionLedgerStore() -> any SubstitutionLedgerStore {
        return MemorySubstitutionLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionLedgerStore: SubstitutionLedgerStore {
        var inner: MemorySubstitutionLedgerStore
        var cache: TTLCache<SubstitutionLedger>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionLedgerStore, cache: TTLCache<SubstitutionLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionLedger? {
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

        func save(_ item: SubstitutionLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionLedger] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionLedgerStore(_ inner: MemorySubstitutionLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionLedgerStore {
        return CachedSubstitutionLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution ledgers. Empty fields match all.
    final class SubstitutionLedgerQuery {
        var category: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRetries: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionLedger) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionLedger]) -> [SubstitutionLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionLedgers(_ store: any SubstitutionLedgerStore, query: SubstitutionLedgerQuery) -> [SubstitutionLedger] {
        return query.apply(store.list())
    }
}
