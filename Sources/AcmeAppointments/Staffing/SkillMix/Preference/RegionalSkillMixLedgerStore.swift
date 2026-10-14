import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional skill mix ledgers by code.
    protocol RegionalSkillMixLedgerStore {
        func find(_ code: String) -> RegionalSkillMixLedger?
        func save(_ item: RegionalSkillMixLedger)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalSkillMixLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalSkillMixLedgerStore: RegionalSkillMixLedgerStore {
        var items: [String: RegionalSkillMixLedger]
        var order: [String]

        init(items: [String: RegionalSkillMixLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalSkillMixLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalSkillMixLedger) {
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

        func list() -> [RegionalSkillMixLedger] {
            var out: [RegionalSkillMixLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalSkillMixLedgerStore() -> any RegionalSkillMixLedgerStore {
        return MemoryRegionalSkillMixLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalSkillMixLedgerStore: RegionalSkillMixLedgerStore {
        var inner: MemoryRegionalSkillMixLedgerStore
        var cache: TTLCache<RegionalSkillMixLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalSkillMixLedgerStore, cache: TTLCache<RegionalSkillMixLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalSkillMixLedger? {
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

        func save(_ item: RegionalSkillMixLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalSkillMixLedger] {
            return inner.list()
        }
    }

    static func newCachedRegionalSkillMixLedgerStore(_ inner: MemoryRegionalSkillMixLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalSkillMixLedgerStore {
        return CachedRegionalSkillMixLedgerStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional skill mix ledgers. Empty fields match all.
    final class RegionalSkillMixLedgerQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalSkillMixLedger) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalSkillMixLedger]) -> [RegionalSkillMixLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalSkillMixLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalSkillMixLedgers(_ store: any RegionalSkillMixLedgerStore, query: RegionalSkillMixLedgerQuery) -> [RegionalSkillMixLedger] {
        return query.apply(store.list())
    }
}
