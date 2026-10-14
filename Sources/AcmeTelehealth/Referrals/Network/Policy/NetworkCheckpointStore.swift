import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network checkpoints by code.
    protocol NetworkCheckpointStore {
        func find(_ code: String) -> NetworkCheckpoint?
        func save(_ item: NetworkCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkCheckpointStore: NetworkCheckpointStore {
        var items: [String: NetworkCheckpoint]
        var order: [String]

        init(items: [String: NetworkCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkCheckpoint) {
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

        func list() -> [NetworkCheckpoint] {
            var out: [NetworkCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkCheckpointStore() -> any NetworkCheckpointStore {
        return MemoryNetworkCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkCheckpointStore: NetworkCheckpointStore {
        var inner: MemoryNetworkCheckpointStore
        var cache: TTLCache<NetworkCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkCheckpointStore, cache: TTLCache<NetworkCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkCheckpoint? {
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

        func save(_ item: NetworkCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedNetworkCheckpointStore(_ inner: MemoryNetworkCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkCheckpointStore {
        return CachedNetworkCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network checkpoints. Empty fields match all.
    final class NetworkCheckpointQuery {
        var region: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minWeight: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkCheckpoint) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [NetworkCheckpoint]) -> [NetworkCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkCheckpoints(_ store: any NetworkCheckpointStore, query: NetworkCheckpointQuery) -> [NetworkCheckpoint] {
        return query.apply(store.list())
    }
}
