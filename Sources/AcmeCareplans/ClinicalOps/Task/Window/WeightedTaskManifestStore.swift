import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps weighted task manifests by code.
    protocol WeightedTaskManifestStore {
        func find(_ code: String) -> WeightedTaskManifest?
        func save(_ item: WeightedTaskManifest)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedTaskManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedTaskManifestStore: WeightedTaskManifestStore {
        var items: [String: WeightedTaskManifest]
        var order: [String]

        init(items: [String: WeightedTaskManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedTaskManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedTaskManifest) {
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

        func list() -> [WeightedTaskManifest] {
            var out: [WeightedTaskManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedTaskManifestStore() -> any WeightedTaskManifestStore {
        return MemoryWeightedTaskManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedTaskManifestStore: WeightedTaskManifestStore {
        var inner: MemoryWeightedTaskManifestStore
        var cache: TTLCache<WeightedTaskManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedTaskManifestStore, cache: TTLCache<WeightedTaskManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedTaskManifest? {
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

        func save(_ item: WeightedTaskManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedTaskManifest] {
            return inner.list()
        }
    }

    static func newCachedWeightedTaskManifestStore(_ inner: MemoryWeightedTaskManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedTaskManifestStore {
        return CachedWeightedTaskManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted task manifests. Empty fields match all.
    final class WeightedTaskManifestQuery {
        var channel: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minSequence: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedTaskManifest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedTaskManifest]) -> [WeightedTaskManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedTaskManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedTaskManifests(_ store: any WeightedTaskManifestStore, query: WeightedTaskManifestQuery) -> [WeightedTaskManifest] {
        return query.apply(store.list())
    }
}
