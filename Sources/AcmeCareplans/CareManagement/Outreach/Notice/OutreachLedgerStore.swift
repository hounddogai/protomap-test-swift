import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach ledgers by code.
    protocol OutreachLedgerStore {
        func find(_ code: String) -> OutreachLedger?
        func save(_ item: OutreachLedger)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachLedgerStore: OutreachLedgerStore {
        var items: [String: OutreachLedger]
        var order: [String]

        init(items: [String: OutreachLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachLedger) {
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

        func list() -> [OutreachLedger] {
            var out: [OutreachLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachLedgerStore() -> any OutreachLedgerStore {
        return MemoryOutreachLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachLedgerStore: OutreachLedgerStore {
        var inner: MemoryOutreachLedgerStore
        var cache: TTLCache<OutreachLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachLedgerStore, cache: TTLCache<OutreachLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachLedger? {
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

        func save(_ item: OutreachLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachLedger] {
            return inner.list()
        }
    }

    static func newCachedOutreachLedgerStore(_ inner: MemoryOutreachLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachLedgerStore {
        return CachedOutreachLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach ledgers. Empty fields match all.
    final class OutreachLedgerQuery {
        var channel: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCopay: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachLedger) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachLedger]) -> [OutreachLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachLedgers(_ store: any OutreachLedgerStore, query: OutreachLedgerQuery) -> [OutreachLedger] {
        return query.apply(store.list())
    }
}
