import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form ledgers by code.
    protocol ConsentFormLedgerStore {
        func find(_ code: String) -> ConsentFormLedger?
        func save(_ item: ConsentFormLedger)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormLedgerStore: ConsentFormLedgerStore {
        var items: [String: ConsentFormLedger]
        var order: [String]

        init(items: [String: ConsentFormLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormLedger) {
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

        func list() -> [ConsentFormLedger] {
            var out: [ConsentFormLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormLedgerStore() -> any ConsentFormLedgerStore {
        return MemoryConsentFormLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormLedgerStore: ConsentFormLedgerStore {
        var inner: MemoryConsentFormLedgerStore
        var cache: TTLCache<ConsentFormLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormLedgerStore, cache: TTLCache<ConsentFormLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormLedger? {
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

        func save(_ item: ConsentFormLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormLedger] {
            return inner.list()
        }
    }

    static func newCachedConsentFormLedgerStore(_ inner: MemoryConsentFormLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormLedgerStore {
        return CachedConsentFormLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form ledgers. Empty fields match all.
    final class ConsentFormLedgerQuery {
        var unit: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRetries: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormLedger) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [ConsentFormLedger]) -> [ConsentFormLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormLedgers(_ store: any ConsentFormLedgerStore, query: ConsentFormLedgerQuery) -> [ConsentFormLedger] {
        return query.apply(store.list())
    }
}
