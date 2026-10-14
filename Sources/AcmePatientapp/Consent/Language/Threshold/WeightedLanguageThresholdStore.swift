import AcmePlatform
import Foundation

extension Consent {
    /// Keeps weighted language thresholds by code.
    protocol WeightedLanguageThresholdStore {
        func find(_ code: String) -> WeightedLanguageThreshold?
        func save(_ item: WeightedLanguageThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedLanguageThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedLanguageThresholdStore: WeightedLanguageThresholdStore {
        var items: [String: WeightedLanguageThreshold]
        var order: [String]

        init(items: [String: WeightedLanguageThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedLanguageThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedLanguageThreshold) {
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

        func list() -> [WeightedLanguageThreshold] {
            var out: [WeightedLanguageThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedLanguageThresholdStore() -> any WeightedLanguageThresholdStore {
        return MemoryWeightedLanguageThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedLanguageThresholdStore: WeightedLanguageThresholdStore {
        var inner: MemoryWeightedLanguageThresholdStore
        var cache: TTLCache<WeightedLanguageThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedLanguageThresholdStore, cache: TTLCache<WeightedLanguageThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedLanguageThreshold? {
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

        func save(_ item: WeightedLanguageThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedLanguageThreshold] {
            return inner.list()
        }
    }

    static func newCachedWeightedLanguageThresholdStore(_ inner: MemoryWeightedLanguageThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedLanguageThresholdStore {
        return CachedWeightedLanguageThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted language thresholds. Empty fields match all.
    final class WeightedLanguageThresholdQuery {
        var category: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedLanguageThreshold) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedLanguageThreshold]) -> [WeightedLanguageThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedLanguageThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedLanguageThresholds(_ store: any WeightedLanguageThresholdStore, query: WeightedLanguageThresholdQuery) -> [WeightedLanguageThreshold] {
        return query.apply(store.list())
    }
}
