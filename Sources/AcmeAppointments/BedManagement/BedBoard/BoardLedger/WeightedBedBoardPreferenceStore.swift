import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps weighted bed board preferences by code.
    protocol WeightedBedBoardPreferenceStore {
        func find(_ code: String) -> WeightedBedBoardPreference?
        func save(_ item: WeightedBedBoardPreference)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedBedBoardPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedBedBoardPreferenceStore: WeightedBedBoardPreferenceStore {
        var items: [String: WeightedBedBoardPreference]
        var order: [String]

        init(items: [String: WeightedBedBoardPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedBedBoardPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedBedBoardPreference) {
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

        func list() -> [WeightedBedBoardPreference] {
            var out: [WeightedBedBoardPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedBedBoardPreferenceStore() -> any WeightedBedBoardPreferenceStore {
        return MemoryWeightedBedBoardPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedBedBoardPreferenceStore: WeightedBedBoardPreferenceStore {
        var inner: MemoryWeightedBedBoardPreferenceStore
        var cache: TTLCache<WeightedBedBoardPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedBedBoardPreferenceStore, cache: TTLCache<WeightedBedBoardPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedBedBoardPreference? {
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

        func save(_ item: WeightedBedBoardPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedBedBoardPreference] {
            return inner.list()
        }
    }

    static func newCachedWeightedBedBoardPreferenceStore(_ inner: MemoryWeightedBedBoardPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedBedBoardPreferenceStore {
        return CachedWeightedBedBoardPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted bed board preferences. Empty fields match all.
    final class WeightedBedBoardPreferenceQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedBedBoardPreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedBedBoardPreference]) -> [WeightedBedBoardPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedBedBoardPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedBedBoardPreferences(_ store: any WeightedBedBoardPreferenceStore, query: WeightedBedBoardPreferenceQuery) -> [WeightedBedBoardPreference] {
        return query.apply(store.list())
    }
}
