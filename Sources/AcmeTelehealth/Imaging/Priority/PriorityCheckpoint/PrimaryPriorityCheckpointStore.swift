import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary priority checkpoints by code.
    protocol PrimaryPriorityCheckpointStore {
        func find(_ code: String) -> PrimaryPriorityCheckpoint?
        func save(_ item: PrimaryPriorityCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryPriorityCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryPriorityCheckpointStore: PrimaryPriorityCheckpointStore {
        var items: [String: PrimaryPriorityCheckpoint]
        var order: [String]

        init(items: [String: PrimaryPriorityCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryPriorityCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryPriorityCheckpoint) {
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

        func list() -> [PrimaryPriorityCheckpoint] {
            var out: [PrimaryPriorityCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryPriorityCheckpointStore() -> any PrimaryPriorityCheckpointStore {
        return MemoryPrimaryPriorityCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryPriorityCheckpointStore: PrimaryPriorityCheckpointStore {
        var inner: MemoryPrimaryPriorityCheckpointStore
        var cache: TTLCache<PrimaryPriorityCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryPriorityCheckpointStore, cache: TTLCache<PrimaryPriorityCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryPriorityCheckpoint? {
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

        func save(_ item: PrimaryPriorityCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryPriorityCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedPrimaryPriorityCheckpointStore(_ inner: MemoryPrimaryPriorityCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryPriorityCheckpointStore {
        return CachedPrimaryPriorityCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary priority checkpoints. Empty fields match all.
    final class PrimaryPriorityCheckpointQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryPriorityCheckpoint) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryPriorityCheckpoint]) -> [PrimaryPriorityCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryPriorityCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryPriorityCheckpoints(_ store: any PrimaryPriorityCheckpointStore, query: PrimaryPriorityCheckpointQuery) -> [PrimaryPriorityCheckpoint] {
        return query.apply(store.list())
    }
}
