import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority checkpoints by code.
    protocol PriorityCheckpointStore {
        func find(_ code: String) -> PriorityCheckpoint?
        func save(_ item: PriorityCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityCheckpointStore: PriorityCheckpointStore {
        var items: [String: PriorityCheckpoint]
        var order: [String]

        init(items: [String: PriorityCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityCheckpoint) {
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

        func list() -> [PriorityCheckpoint] {
            var out: [PriorityCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityCheckpointStore() -> any PriorityCheckpointStore {
        return MemoryPriorityCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityCheckpointStore: PriorityCheckpointStore {
        var inner: MemoryPriorityCheckpointStore
        var cache: TTLCache<PriorityCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityCheckpointStore, cache: TTLCache<PriorityCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityCheckpoint? {
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

        func save(_ item: PriorityCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedPriorityCheckpointStore(_ inner: MemoryPriorityCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityCheckpointStore {
        return CachedPriorityCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority checkpoints. Empty fields match all.
    final class PriorityCheckpointQuery {
        var unit: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCost: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityCheckpoint) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [PriorityCheckpoint]) -> [PriorityCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityCheckpoints(_ store: any PriorityCheckpointStore, query: PriorityCheckpointQuery) -> [PriorityCheckpoint] {
        return query.apply(store.list())
    }
}
