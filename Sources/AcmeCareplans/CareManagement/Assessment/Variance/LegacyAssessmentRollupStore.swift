import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps legacy assessment rollups by code.
    protocol LegacyAssessmentRollupStore {
        func find(_ code: String) -> LegacyAssessmentRollup?
        func save(_ item: LegacyAssessmentRollup)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAssessmentRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAssessmentRollupStore: LegacyAssessmentRollupStore {
        var items: [String: LegacyAssessmentRollup]
        var order: [String]

        init(items: [String: LegacyAssessmentRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAssessmentRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAssessmentRollup) {
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

        func list() -> [LegacyAssessmentRollup] {
            var out: [LegacyAssessmentRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAssessmentRollupStore() -> any LegacyAssessmentRollupStore {
        return MemoryLegacyAssessmentRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAssessmentRollupStore: LegacyAssessmentRollupStore {
        var inner: MemoryLegacyAssessmentRollupStore
        var cache: TTLCache<LegacyAssessmentRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAssessmentRollupStore, cache: TTLCache<LegacyAssessmentRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAssessmentRollup? {
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

        func save(_ item: LegacyAssessmentRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAssessmentRollup] {
            return inner.list()
        }
    }

    static func newCachedLegacyAssessmentRollupStore(_ inner: MemoryLegacyAssessmentRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAssessmentRollupStore {
        return CachedLegacyAssessmentRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy assessment rollups. Empty fields match all.
    final class LegacyAssessmentRollupQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAssessmentRollup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyAssessmentRollup]) -> [LegacyAssessmentRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAssessmentRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAssessmentRollups(_ store: any LegacyAssessmentRollupStore, query: LegacyAssessmentRollupQuery) -> [LegacyAssessmentRollup] {
        return query.apply(store.list())
    }
}
