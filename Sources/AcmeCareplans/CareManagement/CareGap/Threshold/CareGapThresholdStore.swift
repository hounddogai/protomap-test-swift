import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap thresholds by code.
    protocol CareGapThresholdStore {
        func find(_ code: String) -> CareGapThreshold?
        func save(_ item: CareGapThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapThresholdStore: CareGapThresholdStore {
        var items: [String: CareGapThreshold]
        var order: [String]

        init(items: [String: CareGapThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapThreshold) {
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

        func list() -> [CareGapThreshold] {
            var out: [CareGapThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapThresholdStore() -> any CareGapThresholdStore {
        return MemoryCareGapThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapThresholdStore: CareGapThresholdStore {
        var inner: MemoryCareGapThresholdStore
        var cache: TTLCache<CareGapThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapThresholdStore, cache: TTLCache<CareGapThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapThreshold? {
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

        func save(_ item: CareGapThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapThreshold] {
            return inner.list()
        }
    }

    static func newCachedCareGapThresholdStore(_ inner: MemoryCareGapThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapThresholdStore {
        return CachedCareGapThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap thresholds. Empty fields match all.
    final class CareGapThresholdQuery {
        var source: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapThreshold) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapThreshold]) -> [CareGapThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapThresholds(_ store: any CareGapThresholdStore, query: CareGapThresholdQuery) -> [CareGapThreshold] {
        return query.apply(store.list())
    }
}
