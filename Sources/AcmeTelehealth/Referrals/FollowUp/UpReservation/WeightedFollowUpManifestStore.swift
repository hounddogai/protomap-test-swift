import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted follow up manifests by code.
    protocol WeightedFollowUpManifestStore {
        func find(_ code: String) -> WeightedFollowUpManifest?
        func save(_ item: WeightedFollowUpManifest)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedFollowUpManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedFollowUpManifestStore: WeightedFollowUpManifestStore {
        var items: [String: WeightedFollowUpManifest]
        var order: [String]

        init(items: [String: WeightedFollowUpManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedFollowUpManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedFollowUpManifest) {
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

        func list() -> [WeightedFollowUpManifest] {
            var out: [WeightedFollowUpManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedFollowUpManifestStore() -> any WeightedFollowUpManifestStore {
        return MemoryWeightedFollowUpManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedFollowUpManifestStore: WeightedFollowUpManifestStore {
        var inner: MemoryWeightedFollowUpManifestStore
        var cache: TTLCache<WeightedFollowUpManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedFollowUpManifestStore, cache: TTLCache<WeightedFollowUpManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedFollowUpManifest? {
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

        func save(_ item: WeightedFollowUpManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedFollowUpManifest] {
            return inner.list()
        }
    }

    static func newCachedWeightedFollowUpManifestStore(_ inner: MemoryWeightedFollowUpManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedFollowUpManifestStore {
        return CachedWeightedFollowUpManifestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted follow up manifests. Empty fields match all.
    final class WeightedFollowUpManifestQuery {
        var category: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minLimit: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedFollowUpManifest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedFollowUpManifest]) -> [WeightedFollowUpManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedFollowUpManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedFollowUpManifests(_ store: any WeightedFollowUpManifestStore, query: WeightedFollowUpManifestQuery) -> [WeightedFollowUpManifest] {
        return query.apply(store.list())
    }
}
