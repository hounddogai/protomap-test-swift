import AcmePlatform
import Foundation

extension Consent {
    /// Keeps weighted witness entries by code.
    protocol WeightedWitnessEntryStore {
        func find(_ code: String) -> WeightedWitnessEntry?
        func save(_ item: WeightedWitnessEntry)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedWitnessEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedWitnessEntryStore: WeightedWitnessEntryStore {
        var items: [String: WeightedWitnessEntry]
        var order: [String]

        init(items: [String: WeightedWitnessEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedWitnessEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedWitnessEntry) {
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

        func list() -> [WeightedWitnessEntry] {
            var out: [WeightedWitnessEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedWitnessEntryStore() -> any WeightedWitnessEntryStore {
        return MemoryWeightedWitnessEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedWitnessEntryStore: WeightedWitnessEntryStore {
        var inner: MemoryWeightedWitnessEntryStore
        var cache: TTLCache<WeightedWitnessEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedWitnessEntryStore, cache: TTLCache<WeightedWitnessEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedWitnessEntry? {
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

        func save(_ item: WeightedWitnessEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedWitnessEntry] {
            return inner.list()
        }
    }

    static func newCachedWeightedWitnessEntryStore(_ inner: MemoryWeightedWitnessEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedWitnessEntryStore {
        return CachedWeightedWitnessEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted witness entries. Empty fields match all.
    final class WeightedWitnessEntryQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedWitnessEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [WeightedWitnessEntry]) -> [WeightedWitnessEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedWitnessEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedWitnessEntries(_ store: any WeightedWitnessEntryStore, query: WeightedWitnessEntryQuery) -> [WeightedWitnessEntry] {
        return query.apply(store.list())
    }
}
