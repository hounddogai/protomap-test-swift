import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback network checkpoints by code.
    protocol FallbackNetworkCheckpointStore {
        func find(_ code: String) -> FallbackNetworkCheckpoint?
        func save(_ item: FallbackNetworkCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackNetworkCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackNetworkCheckpointStore: FallbackNetworkCheckpointStore {
        var items: [String: FallbackNetworkCheckpoint]
        var order: [String]

        init(items: [String: FallbackNetworkCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackNetworkCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackNetworkCheckpoint) {
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

        func list() -> [FallbackNetworkCheckpoint] {
            var out: [FallbackNetworkCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackNetworkCheckpointStore() -> any FallbackNetworkCheckpointStore {
        return MemoryFallbackNetworkCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackNetworkCheckpointStore: FallbackNetworkCheckpointStore {
        var inner: MemoryFallbackNetworkCheckpointStore
        var cache: TTLCache<FallbackNetworkCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackNetworkCheckpointStore, cache: TTLCache<FallbackNetworkCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackNetworkCheckpoint? {
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

        func save(_ item: FallbackNetworkCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackNetworkCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedFallbackNetworkCheckpointStore(_ inner: MemoryFallbackNetworkCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackNetworkCheckpointStore {
        return CachedFallbackNetworkCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback network checkpoints. Empty fields match all.
    final class FallbackNetworkCheckpointQuery {
        var region: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCost: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackNetworkCheckpoint) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackNetworkCheckpoint]) -> [FallbackNetworkCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackNetworkCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackNetworkCheckpoints(_ store: any FallbackNetworkCheckpointStore, query: FallbackNetworkCheckpointQuery) -> [FallbackNetworkCheckpoint] {
        return query.apply(store.list())
    }
}
