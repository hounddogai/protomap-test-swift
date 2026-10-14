import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language ledgers by code.
    protocol LanguageLedgerStore {
        func find(_ code: String) -> LanguageLedger?
        func save(_ item: LanguageLedger)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageLedgerStore: LanguageLedgerStore {
        var items: [String: LanguageLedger]
        var order: [String]

        init(items: [String: LanguageLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageLedger) {
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

        func list() -> [LanguageLedger] {
            var out: [LanguageLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageLedgerStore() -> any LanguageLedgerStore {
        return MemoryLanguageLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageLedgerStore: LanguageLedgerStore {
        var inner: MemoryLanguageLedgerStore
        var cache: TTLCache<LanguageLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageLedgerStore, cache: TTLCache<LanguageLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageLedger? {
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

        func save(_ item: LanguageLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageLedger] {
            return inner.list()
        }
    }

    static func newCachedLanguageLedgerStore(_ inner: MemoryLanguageLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageLedgerStore {
        return CachedLanguageLedgerStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language ledgers. Empty fields match all.
    final class LanguageLedgerQuery {
        var locale: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageLedger) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageLedger]) -> [LanguageLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageLedgers(_ store: any LanguageLedgerStore, query: LanguageLedgerQuery) -> [LanguageLedger] {
        return query.apply(store.list())
    }
}
