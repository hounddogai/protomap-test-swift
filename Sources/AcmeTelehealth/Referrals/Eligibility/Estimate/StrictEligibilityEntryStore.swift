import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps strict eligibility entries by code.
    protocol StrictEligibilityEntryStore {
        func find(_ code: String) -> StrictEligibilityEntry?
        func save(_ item: StrictEligibilityEntry)
        func remove(_ code: String) -> Bool
        func list() -> [StrictEligibilityEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictEligibilityEntryStore: StrictEligibilityEntryStore {
        var items: [String: StrictEligibilityEntry]
        var order: [String]

        init(items: [String: StrictEligibilityEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictEligibilityEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictEligibilityEntry) {
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

        func list() -> [StrictEligibilityEntry] {
            var out: [StrictEligibilityEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictEligibilityEntryStore() -> any StrictEligibilityEntryStore {
        return MemoryStrictEligibilityEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictEligibilityEntryStore: StrictEligibilityEntryStore {
        var inner: MemoryStrictEligibilityEntryStore
        var cache: TTLCache<StrictEligibilityEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictEligibilityEntryStore, cache: TTLCache<StrictEligibilityEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictEligibilityEntry? {
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

        func save(_ item: StrictEligibilityEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictEligibilityEntry] {
            return inner.list()
        }
    }

    static func newCachedStrictEligibilityEntryStore(_ inner: MemoryStrictEligibilityEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictEligibilityEntryStore {
        return CachedStrictEligibilityEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict eligibility entries. Empty fields match all.
    final class StrictEligibilityEntryQuery {
        var unit: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minRatio: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictEligibilityEntry) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictEligibilityEntry]) -> [StrictEligibilityEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictEligibilityEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictEligibilityEntries(_ store: any StrictEligibilityEntryStore, query: StrictEligibilityEntryQuery) -> [StrictEligibilityEntry] {
        return query.apply(store.list())
    }
}
