import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps primary program checkpoints by code.
    protocol PrimaryProgramCheckpointStore {
        func find(_ code: String) -> PrimaryProgramCheckpoint?
        func save(_ item: PrimaryProgramCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryProgramCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryProgramCheckpointStore: PrimaryProgramCheckpointStore {
        var items: [String: PrimaryProgramCheckpoint]
        var order: [String]

        init(items: [String: PrimaryProgramCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryProgramCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryProgramCheckpoint) {
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

        func list() -> [PrimaryProgramCheckpoint] {
            var out: [PrimaryProgramCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryProgramCheckpointStore() -> any PrimaryProgramCheckpointStore {
        return MemoryPrimaryProgramCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryProgramCheckpointStore: PrimaryProgramCheckpointStore {
        var inner: MemoryPrimaryProgramCheckpointStore
        var cache: TTLCache<PrimaryProgramCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryProgramCheckpointStore, cache: TTLCache<PrimaryProgramCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryProgramCheckpoint? {
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

        func save(_ item: PrimaryProgramCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryProgramCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedPrimaryProgramCheckpointStore(_ inner: MemoryPrimaryProgramCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryProgramCheckpointStore {
        return CachedPrimaryProgramCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary program checkpoints. Empty fields match all.
    final class PrimaryProgramCheckpointQuery {
        var source: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryProgramCheckpoint) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryProgramCheckpoint]) -> [PrimaryProgramCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryProgramCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryProgramCheckpoints(_ store: any PrimaryProgramCheckpointStore, query: PrimaryProgramCheckpointQuery) -> [PrimaryProgramCheckpoint] {
        return query.apply(store.list())
    }
}
