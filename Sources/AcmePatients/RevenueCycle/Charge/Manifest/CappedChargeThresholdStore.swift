import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped charge thresholds by code.
    protocol CappedChargeThresholdStore {
        func find(_ code: String) -> CappedChargeThreshold?
        func save(_ item: CappedChargeThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [CappedChargeThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedChargeThresholdStore: CappedChargeThresholdStore {
        var items: [String: CappedChargeThreshold]
        var order: [String]

        init(items: [String: CappedChargeThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedChargeThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedChargeThreshold) {
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

        func list() -> [CappedChargeThreshold] {
            var out: [CappedChargeThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedChargeThresholdStore() -> any CappedChargeThresholdStore {
        return MemoryCappedChargeThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedChargeThresholdStore: CappedChargeThresholdStore {
        var inner: MemoryCappedChargeThresholdStore
        var cache: TTLCache<CappedChargeThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedChargeThresholdStore, cache: TTLCache<CappedChargeThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedChargeThreshold? {
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

        func save(_ item: CappedChargeThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedChargeThreshold] {
            return inner.list()
        }
    }

    static func newCachedCappedChargeThresholdStore(_ inner: MemoryCappedChargeThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedChargeThresholdStore {
        return CachedCappedChargeThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped charge thresholds. Empty fields match all.
    final class CappedChargeThresholdQuery {
        var category: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedChargeThreshold) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [CappedChargeThreshold]) -> [CappedChargeThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedChargeThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedChargeThresholds(_ store: any CappedChargeThresholdStore, query: CappedChargeThresholdQuery) -> [CappedChargeThreshold] {
        return query.apply(store.list())
    }
}
