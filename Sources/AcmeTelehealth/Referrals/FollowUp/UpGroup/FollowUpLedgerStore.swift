import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up ledgers by code.
    protocol FollowUpLedgerStore {
        func find(_ code: String) -> FollowUpLedger?
        func save(_ item: FollowUpLedger)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpLedgerStore: FollowUpLedgerStore {
        var items: [String: FollowUpLedger]
        var order: [String]

        init(items: [String: FollowUpLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpLedger) {
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

        func list() -> [FollowUpLedger] {
            var out: [FollowUpLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpLedgerStore() -> any FollowUpLedgerStore {
        return MemoryFollowUpLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpLedgerStore: FollowUpLedgerStore {
        var inner: MemoryFollowUpLedgerStore
        var cache: TTLCache<FollowUpLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpLedgerStore, cache: TTLCache<FollowUpLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpLedger? {
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

        func save(_ item: FollowUpLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpLedger] {
            return inner.list()
        }
    }

    static func newCachedFollowUpLedgerStore(_ inner: MemoryFollowUpLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpLedgerStore {
        return CachedFollowUpLedgerStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up ledgers. Empty fields match all.
    final class FollowUpLedgerQuery {
        var source: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpLedger) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpLedger]) -> [FollowUpLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpLedgers(_ store: any FollowUpLedgerStore, query: FollowUpLedgerQuery) -> [FollowUpLedger] {
        return query.apply(store.list())
    }
}
