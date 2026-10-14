import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive risk score thresholds by code.
    protocol AdaptiveRiskScoreThresholdStore {
        func find(_ code: String) -> AdaptiveRiskScoreThreshold?
        func save(_ item: AdaptiveRiskScoreThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveRiskScoreThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveRiskScoreThresholdStore: AdaptiveRiskScoreThresholdStore {
        var items: [String: AdaptiveRiskScoreThreshold]
        var order: [String]

        init(items: [String: AdaptiveRiskScoreThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveRiskScoreThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveRiskScoreThreshold) {
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

        func list() -> [AdaptiveRiskScoreThreshold] {
            var out: [AdaptiveRiskScoreThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveRiskScoreThresholdStore() -> any AdaptiveRiskScoreThresholdStore {
        return MemoryAdaptiveRiskScoreThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveRiskScoreThresholdStore: AdaptiveRiskScoreThresholdStore {
        var inner: MemoryAdaptiveRiskScoreThresholdStore
        var cache: TTLCache<AdaptiveRiskScoreThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveRiskScoreThresholdStore, cache: TTLCache<AdaptiveRiskScoreThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveRiskScoreThreshold? {
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

        func save(_ item: AdaptiveRiskScoreThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveRiskScoreThreshold] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveRiskScoreThresholdStore(_ inner: MemoryAdaptiveRiskScoreThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveRiskScoreThresholdStore {
        return CachedAdaptiveRiskScoreThresholdStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive risk score thresholds. Empty fields match all.
    final class AdaptiveRiskScoreThresholdQuery {
        var ward: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRevision: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveRiskScoreThreshold) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [AdaptiveRiskScoreThreshold]) -> [AdaptiveRiskScoreThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveRiskScoreThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveRiskScoreThresholds(_ store: any AdaptiveRiskScoreThresholdStore, query: AdaptiveRiskScoreThresholdQuery) -> [AdaptiveRiskScoreThreshold] {
        return query.apply(store.list())
    }
}
