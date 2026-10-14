import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional witness entries by code.
    protocol RegionalWitnessEntryStore {
        func find(_ code: String) -> RegionalWitnessEntry?
        func save(_ item: RegionalWitnessEntry)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalWitnessEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalWitnessEntryStore: RegionalWitnessEntryStore {
        var items: [String: RegionalWitnessEntry]
        var order: [String]

        init(items: [String: RegionalWitnessEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalWitnessEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalWitnessEntry) {
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

        func list() -> [RegionalWitnessEntry] {
            var out: [RegionalWitnessEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalWitnessEntryStore() -> any RegionalWitnessEntryStore {
        return MemoryRegionalWitnessEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalWitnessEntryStore: RegionalWitnessEntryStore {
        var inner: MemoryRegionalWitnessEntryStore
        var cache: TTLCache<RegionalWitnessEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalWitnessEntryStore, cache: TTLCache<RegionalWitnessEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalWitnessEntry? {
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

        func save(_ item: RegionalWitnessEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalWitnessEntry] {
            return inner.list()
        }
    }

    static func newCachedRegionalWitnessEntryStore(_ inner: MemoryRegionalWitnessEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalWitnessEntryStore {
        return CachedRegionalWitnessEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional witness entries. Empty fields match all.
    final class RegionalWitnessEntryQuery {
        var category: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minAmount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalWitnessEntry) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalWitnessEntry]) -> [RegionalWitnessEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalWitnessEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalWitnessEntries(_ store: any RegionalWitnessEntryStore, query: RegionalWitnessEntryQuery) -> [RegionalWitnessEntry] {
        return query.apply(store.list())
    }
}
