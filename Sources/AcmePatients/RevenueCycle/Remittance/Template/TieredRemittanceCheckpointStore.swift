import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered remittance checkpoints by code.
    protocol TieredRemittanceCheckpointStore {
        func find(_ code: String) -> TieredRemittanceCheckpoint?
        func save(_ item: TieredRemittanceCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRemittanceCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRemittanceCheckpointStore: TieredRemittanceCheckpointStore {
        var items: [String: TieredRemittanceCheckpoint]
        var order: [String]

        init(items: [String: TieredRemittanceCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRemittanceCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRemittanceCheckpoint) {
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

        func list() -> [TieredRemittanceCheckpoint] {
            var out: [TieredRemittanceCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRemittanceCheckpointStore() -> any TieredRemittanceCheckpointStore {
        return MemoryTieredRemittanceCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRemittanceCheckpointStore: TieredRemittanceCheckpointStore {
        var inner: MemoryTieredRemittanceCheckpointStore
        var cache: TTLCache<TieredRemittanceCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRemittanceCheckpointStore, cache: TTLCache<TieredRemittanceCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRemittanceCheckpoint? {
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

        func save(_ item: TieredRemittanceCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRemittanceCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedTieredRemittanceCheckpointStore(_ inner: MemoryTieredRemittanceCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRemittanceCheckpointStore {
        return CachedTieredRemittanceCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered remittance checkpoints. Empty fields match all.
    final class TieredRemittanceCheckpointQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRemittanceCheckpoint) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredRemittanceCheckpoint]) -> [TieredRemittanceCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRemittanceCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRemittanceCheckpoints(_ store: any TieredRemittanceCheckpointStore, query: TieredRemittanceCheckpointQuery) -> [TieredRemittanceCheckpoint] {
        return query.apply(store.list())
    }
}
