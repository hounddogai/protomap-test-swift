import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps adaptive study ledgers by code.
    protocol AdaptiveStudyLedgerStore {
        func find(_ code: String) -> AdaptiveStudyLedger?
        func save(_ item: AdaptiveStudyLedger)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveStudyLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveStudyLedgerStore: AdaptiveStudyLedgerStore {
        var items: [String: AdaptiveStudyLedger]
        var order: [String]

        init(items: [String: AdaptiveStudyLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveStudyLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveStudyLedger) {
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

        func list() -> [AdaptiveStudyLedger] {
            var out: [AdaptiveStudyLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveStudyLedgerStore() -> any AdaptiveStudyLedgerStore {
        return MemoryAdaptiveStudyLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveStudyLedgerStore: AdaptiveStudyLedgerStore {
        var inner: MemoryAdaptiveStudyLedgerStore
        var cache: TTLCache<AdaptiveStudyLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveStudyLedgerStore, cache: TTLCache<AdaptiveStudyLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveStudyLedger? {
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

        func save(_ item: AdaptiveStudyLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveStudyLedger] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveStudyLedgerStore(_ inner: MemoryAdaptiveStudyLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveStudyLedgerStore {
        return CachedAdaptiveStudyLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive study ledgers. Empty fields match all.
    final class AdaptiveStudyLedgerQuery {
        var unit: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveStudyLedger) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveStudyLedger]) -> [AdaptiveStudyLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveStudyLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveStudyLedgers(_ store: any AdaptiveStudyLedgerStore, query: AdaptiveStudyLedgerQuery) -> [AdaptiveStudyLedger] {
        return query.apply(store.list())
    }
}
