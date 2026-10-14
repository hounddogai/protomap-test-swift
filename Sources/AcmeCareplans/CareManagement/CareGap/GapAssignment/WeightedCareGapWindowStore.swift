import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted care gap windows by code.
    protocol WeightedCareGapWindowStore {
        func find(_ code: String) -> WeightedCareGapWindow?
        func save(_ item: WeightedCareGapWindow)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedCareGapWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedCareGapWindowStore: WeightedCareGapWindowStore {
        var items: [String: WeightedCareGapWindow]
        var order: [String]

        init(items: [String: WeightedCareGapWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedCareGapWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedCareGapWindow) {
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

        func list() -> [WeightedCareGapWindow] {
            var out: [WeightedCareGapWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedCareGapWindowStore() -> any WeightedCareGapWindowStore {
        return MemoryWeightedCareGapWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedCareGapWindowStore: WeightedCareGapWindowStore {
        var inner: MemoryWeightedCareGapWindowStore
        var cache: TTLCache<WeightedCareGapWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedCareGapWindowStore, cache: TTLCache<WeightedCareGapWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedCareGapWindow? {
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

        func save(_ item: WeightedCareGapWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedCareGapWindow] {
            return inner.list()
        }
    }

    static func newCachedWeightedCareGapWindowStore(_ inner: MemoryWeightedCareGapWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedCareGapWindowStore {
        return CachedWeightedCareGapWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted care gap windows. Empty fields match all.
    final class WeightedCareGapWindowQuery {
        var channel: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRevision: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedCareGapWindow) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedCareGapWindow]) -> [WeightedCareGapWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedCareGapWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedCareGapWindows(_ store: any WeightedCareGapWindowStore, query: WeightedCareGapWindowQuery) -> [WeightedCareGapWindow] {
        return query.apply(store.list())
    }
}
