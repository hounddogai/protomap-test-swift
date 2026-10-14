import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network manifests by code.
    protocol NetworkManifestStore {
        func find(_ code: String) -> NetworkManifest?
        func save(_ item: NetworkManifest)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkManifestStore: NetworkManifestStore {
        var items: [String: NetworkManifest]
        var order: [String]

        init(items: [String: NetworkManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkManifest) {
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

        func list() -> [NetworkManifest] {
            var out: [NetworkManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkManifestStore() -> any NetworkManifestStore {
        return MemoryNetworkManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkManifestStore: NetworkManifestStore {
        var inner: MemoryNetworkManifestStore
        var cache: TTLCache<NetworkManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkManifestStore, cache: TTLCache<NetworkManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkManifest? {
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

        func save(_ item: NetworkManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkManifest] {
            return inner.list()
        }
    }

    static func newCachedNetworkManifestStore(_ inner: MemoryNetworkManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkManifestStore {
        return CachedNetworkManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network manifests. Empty fields match all.
    final class NetworkManifestQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [NetworkManifest]) -> [NetworkManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkManifests(_ store: any NetworkManifestStore, query: NetworkManifestQuery) -> [NetworkManifest] {
        return query.apply(store.list())
    }
}
