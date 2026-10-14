import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive statement thresholds by code.
    protocol AdaptiveStatementThresholdStore {
        func find(_ code: String) -> AdaptiveStatementThreshold?
        func save(_ item: AdaptiveStatementThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveStatementThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveStatementThresholdStore: AdaptiveStatementThresholdStore {
        var items: [String: AdaptiveStatementThreshold]
        var order: [String]

        init(items: [String: AdaptiveStatementThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveStatementThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveStatementThreshold) {
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

        func list() -> [AdaptiveStatementThreshold] {
            var out: [AdaptiveStatementThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveStatementThresholdStore() -> any AdaptiveStatementThresholdStore {
        return MemoryAdaptiveStatementThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveStatementThresholdStore: AdaptiveStatementThresholdStore {
        var inner: MemoryAdaptiveStatementThresholdStore
        var cache: TTLCache<AdaptiveStatementThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveStatementThresholdStore, cache: TTLCache<AdaptiveStatementThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveStatementThreshold? {
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

        func save(_ item: AdaptiveStatementThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveStatementThreshold] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveStatementThresholdStore(_ inner: MemoryAdaptiveStatementThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveStatementThresholdStore {
        return CachedAdaptiveStatementThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive statement thresholds. Empty fields match all.
    final class AdaptiveStatementThresholdQuery {
        var label: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveStatementThreshold) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveStatementThreshold]) -> [AdaptiveStatementThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveStatementThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveStatementThresholds(_ store: any AdaptiveStatementThresholdStore, query: AdaptiveStatementThresholdQuery) -> [AdaptiveStatementThreshold] {
        return query.apply(store.list())
    }
}
