import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps global census checkpoints by code.
    protocol GlobalCensusCheckpointStore {
        func find(_ code: String) -> GlobalCensusCheckpoint?
        func save(_ item: GlobalCensusCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCensusCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCensusCheckpointStore: GlobalCensusCheckpointStore {
        var items: [String: GlobalCensusCheckpoint]
        var order: [String]

        init(items: [String: GlobalCensusCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCensusCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCensusCheckpoint) {
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

        func list() -> [GlobalCensusCheckpoint] {
            var out: [GlobalCensusCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCensusCheckpointStore() -> any GlobalCensusCheckpointStore {
        return MemoryGlobalCensusCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCensusCheckpointStore: GlobalCensusCheckpointStore {
        var inner: MemoryGlobalCensusCheckpointStore
        var cache: TTLCache<GlobalCensusCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCensusCheckpointStore, cache: TTLCache<GlobalCensusCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCensusCheckpoint? {
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

        func save(_ item: GlobalCensusCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCensusCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedGlobalCensusCheckpointStore(_ inner: MemoryGlobalCensusCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCensusCheckpointStore {
        return CachedGlobalCensusCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global census checkpoints. Empty fields match all.
    final class GlobalCensusCheckpointQuery {
        var unit: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCensusCheckpoint) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalCensusCheckpoint]) -> [GlobalCensusCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCensusCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCensusCheckpoints(_ store: any GlobalCensusCheckpointStore, query: GlobalCensusCheckpointQuery) -> [GlobalCensusCheckpoint] {
        return query.apply(store.list())
    }
}
