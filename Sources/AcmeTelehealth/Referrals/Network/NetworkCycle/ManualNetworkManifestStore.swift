import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual network manifests by code.
    protocol ManualNetworkManifestStore {
        func find(_ code: String) -> ManualNetworkManifest?
        func save(_ item: ManualNetworkManifest)
        func remove(_ code: String) -> Bool
        func list() -> [ManualNetworkManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualNetworkManifestStore: ManualNetworkManifestStore {
        var items: [String: ManualNetworkManifest]
        var order: [String]

        init(items: [String: ManualNetworkManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualNetworkManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualNetworkManifest) {
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

        func list() -> [ManualNetworkManifest] {
            var out: [ManualNetworkManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualNetworkManifestStore() -> any ManualNetworkManifestStore {
        return MemoryManualNetworkManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualNetworkManifestStore: ManualNetworkManifestStore {
        var inner: MemoryManualNetworkManifestStore
        var cache: TTLCache<ManualNetworkManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualNetworkManifestStore, cache: TTLCache<ManualNetworkManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualNetworkManifest? {
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

        func save(_ item: ManualNetworkManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualNetworkManifest] {
            return inner.list()
        }
    }

    static func newCachedManualNetworkManifestStore(_ inner: MemoryManualNetworkManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualNetworkManifestStore {
        return CachedManualNetworkManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual network manifests. Empty fields match all.
    final class ManualNetworkManifestQuery {
        var channel: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRefills: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualNetworkManifest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualNetworkManifest]) -> [ManualNetworkManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualNetworkManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualNetworkManifests(_ store: any ManualNetworkManifestStore, query: ManualNetworkManifestQuery) -> [ManualNetworkManifest] {
        return query.apply(store.list())
    }
}
