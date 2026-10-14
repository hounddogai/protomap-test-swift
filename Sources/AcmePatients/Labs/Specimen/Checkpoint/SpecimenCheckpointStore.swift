import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen checkpoints by code.
    protocol SpecimenCheckpointStore {
        func find(_ code: String) -> SpecimenCheckpoint?
        func save(_ item: SpecimenCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenCheckpointStore: SpecimenCheckpointStore {
        var items: [String: SpecimenCheckpoint]
        var order: [String]

        init(items: [String: SpecimenCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenCheckpoint) {
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

        func list() -> [SpecimenCheckpoint] {
            var out: [SpecimenCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenCheckpointStore() -> any SpecimenCheckpointStore {
        return MemorySpecimenCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenCheckpointStore: SpecimenCheckpointStore {
        var inner: MemorySpecimenCheckpointStore
        var cache: TTLCache<SpecimenCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenCheckpointStore, cache: TTLCache<SpecimenCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenCheckpoint? {
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

        func save(_ item: SpecimenCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedSpecimenCheckpointStore(_ inner: MemorySpecimenCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenCheckpointStore {
        return CachedSpecimenCheckpointStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen checkpoints. Empty fields match all.
    final class SpecimenCheckpointQuery {
        var facility: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minPriority: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenCheckpoint) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenCheckpoint]) -> [SpecimenCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenCheckpoints(_ store: any SpecimenCheckpointStore, query: SpecimenCheckpointQuery) -> [SpecimenCheckpoint] {
        return query.apply(store.list())
    }
}
