import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled language ledgers by code.
    protocol ScheduledLanguageLedgerStore {
        func find(_ code: String) -> ScheduledLanguageLedger?
        func save(_ item: ScheduledLanguageLedger)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledLanguageLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledLanguageLedgerStore: ScheduledLanguageLedgerStore {
        var items: [String: ScheduledLanguageLedger]
        var order: [String]

        init(items: [String: ScheduledLanguageLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledLanguageLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledLanguageLedger) {
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

        func list() -> [ScheduledLanguageLedger] {
            var out: [ScheduledLanguageLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledLanguageLedgerStore() -> any ScheduledLanguageLedgerStore {
        return MemoryScheduledLanguageLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledLanguageLedgerStore: ScheduledLanguageLedgerStore {
        var inner: MemoryScheduledLanguageLedgerStore
        var cache: TTLCache<ScheduledLanguageLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledLanguageLedgerStore, cache: TTLCache<ScheduledLanguageLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledLanguageLedger? {
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

        func save(_ item: ScheduledLanguageLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledLanguageLedger] {
            return inner.list()
        }
    }

    static func newCachedScheduledLanguageLedgerStore(_ inner: MemoryScheduledLanguageLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledLanguageLedgerStore {
        return CachedScheduledLanguageLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled language ledgers. Empty fields match all.
    final class ScheduledLanguageLedgerQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledLanguageLedger) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledLanguageLedger]) -> [ScheduledLanguageLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledLanguageLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledLanguageLedgers(_ store: any ScheduledLanguageLedgerStore, query: ScheduledLanguageLedgerQuery) -> [ScheduledLanguageLedger] {
        return query.apply(store.list())
    }
}
