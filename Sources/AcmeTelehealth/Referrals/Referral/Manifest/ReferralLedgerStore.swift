import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral ledgers by code.
    protocol ReferralLedgerStore {
        func find(_ code: String) -> ReferralLedger?
        func save(_ item: ReferralLedger)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralLedgerStore: ReferralLedgerStore {
        var items: [String: ReferralLedger]
        var order: [String]

        init(items: [String: ReferralLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralLedger) {
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

        func list() -> [ReferralLedger] {
            var out: [ReferralLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralLedgerStore() -> any ReferralLedgerStore {
        return MemoryReferralLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralLedgerStore: ReferralLedgerStore {
        var inner: MemoryReferralLedgerStore
        var cache: TTLCache<ReferralLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralLedgerStore, cache: TTLCache<ReferralLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralLedger? {
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

        func save(_ item: ReferralLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralLedger] {
            return inner.list()
        }
    }

    static func newCachedReferralLedgerStore(_ inner: MemoryReferralLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralLedgerStore {
        return CachedReferralLedgerStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral ledgers. Empty fields match all.
    final class ReferralLedgerQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralLedger) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralLedger]) -> [ReferralLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralLedgers(_ store: any ReferralLedgerStore, query: ReferralLedgerQuery) -> [ReferralLedger] {
        return query.apply(store.list())
    }
}
