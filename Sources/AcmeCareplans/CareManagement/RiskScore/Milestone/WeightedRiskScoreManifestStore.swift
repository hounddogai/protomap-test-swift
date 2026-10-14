import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted risk score manifests by code.
    protocol WeightedRiskScoreManifestStore {
        func find(_ code: String) -> WeightedRiskScoreManifest?
        func save(_ item: WeightedRiskScoreManifest)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedRiskScoreManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedRiskScoreManifestStore: WeightedRiskScoreManifestStore {
        var items: [String: WeightedRiskScoreManifest]
        var order: [String]

        init(items: [String: WeightedRiskScoreManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedRiskScoreManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedRiskScoreManifest) {
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

        func list() -> [WeightedRiskScoreManifest] {
            var out: [WeightedRiskScoreManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedRiskScoreManifestStore() -> any WeightedRiskScoreManifestStore {
        return MemoryWeightedRiskScoreManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedRiskScoreManifestStore: WeightedRiskScoreManifestStore {
        var inner: MemoryWeightedRiskScoreManifestStore
        var cache: TTLCache<WeightedRiskScoreManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedRiskScoreManifestStore, cache: TTLCache<WeightedRiskScoreManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedRiskScoreManifest? {
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

        func save(_ item: WeightedRiskScoreManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedRiskScoreManifest] {
            return inner.list()
        }
    }

    static func newCachedWeightedRiskScoreManifestStore(_ inner: MemoryWeightedRiskScoreManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedRiskScoreManifestStore {
        return CachedWeightedRiskScoreManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted risk score manifests. Empty fields match all.
    final class WeightedRiskScoreManifestQuery {
        var facility: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minBudget: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedRiskScoreManifest) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedRiskScoreManifest]) -> [WeightedRiskScoreManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedRiskScoreManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedRiskScoreManifests(_ store: any WeightedRiskScoreManifestStore, query: WeightedRiskScoreManifestQuery) -> [WeightedRiskScoreManifest] {
        return query.apply(store.list())
    }
}
