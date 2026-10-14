import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive assessment thresholds by code.
    protocol AdaptiveAssessmentThresholdStore {
        func find(_ code: String) -> AdaptiveAssessmentThreshold?
        func save(_ item: AdaptiveAssessmentThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveAssessmentThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveAssessmentThresholdStore: AdaptiveAssessmentThresholdStore {
        var items: [String: AdaptiveAssessmentThreshold]
        var order: [String]

        init(items: [String: AdaptiveAssessmentThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveAssessmentThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveAssessmentThreshold) {
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

        func list() -> [AdaptiveAssessmentThreshold] {
            var out: [AdaptiveAssessmentThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveAssessmentThresholdStore() -> any AdaptiveAssessmentThresholdStore {
        return MemoryAdaptiveAssessmentThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveAssessmentThresholdStore: AdaptiveAssessmentThresholdStore {
        var inner: MemoryAdaptiveAssessmentThresholdStore
        var cache: TTLCache<AdaptiveAssessmentThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveAssessmentThresholdStore, cache: TTLCache<AdaptiveAssessmentThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveAssessmentThreshold? {
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

        func save(_ item: AdaptiveAssessmentThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveAssessmentThreshold] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveAssessmentThresholdStore(_ inner: MemoryAdaptiveAssessmentThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveAssessmentThresholdStore {
        return CachedAdaptiveAssessmentThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive assessment thresholds. Empty fields match all.
    final class AdaptiveAssessmentThresholdQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveAssessmentThreshold) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveAssessmentThreshold]) -> [AdaptiveAssessmentThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveAssessmentThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveAssessmentThresholds(_ store: any AdaptiveAssessmentThresholdStore, query: AdaptiveAssessmentThresholdQuery) -> [AdaptiveAssessmentThreshold] {
        return query.apply(store.list())
    }
}
