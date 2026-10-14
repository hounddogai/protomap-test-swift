import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient language ledgers by code.
    protocol LenientLanguageLedgerStore {
        func find(_ code: String) -> LenientLanguageLedger?
        func save(_ item: LenientLanguageLedger)
        func remove(_ code: String) -> Bool
        func list() -> [LenientLanguageLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientLanguageLedgerStore: LenientLanguageLedgerStore {
        var items: [String: LenientLanguageLedger]
        var order: [String]

        init(items: [String: LenientLanguageLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientLanguageLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientLanguageLedger) {
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

        func list() -> [LenientLanguageLedger] {
            var out: [LenientLanguageLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientLanguageLedgerStore() -> any LenientLanguageLedgerStore {
        return MemoryLenientLanguageLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientLanguageLedgerStore: LenientLanguageLedgerStore {
        var inner: MemoryLenientLanguageLedgerStore
        var cache: TTLCache<LenientLanguageLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientLanguageLedgerStore, cache: TTLCache<LenientLanguageLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientLanguageLedger? {
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

        func save(_ item: LenientLanguageLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientLanguageLedger] {
            return inner.list()
        }
    }

    static func newCachedLenientLanguageLedgerStore(_ inner: MemoryLenientLanguageLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientLanguageLedgerStore {
        return CachedLenientLanguageLedgerStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient language ledgers. Empty fields match all.
    final class LenientLanguageLedgerQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientLanguageLedger) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientLanguageLedger]) -> [LenientLanguageLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientLanguageLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientLanguageLedgers(_ store: any LenientLanguageLedgerStore, query: LenientLanguageLedgerQuery) -> [LenientLanguageLedger] {
        return query.apply(store.list())
    }
}
