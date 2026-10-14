import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan checkpoints by code.
    protocol AcuityPlanCheckpointStore {
        func find(_ code: String) -> AcuityPlanCheckpoint?
        func save(_ item: AcuityPlanCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanCheckpointStore: AcuityPlanCheckpointStore {
        var items: [String: AcuityPlanCheckpoint]
        var order: [String]

        init(items: [String: AcuityPlanCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanCheckpoint) {
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

        func list() -> [AcuityPlanCheckpoint] {
            var out: [AcuityPlanCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanCheckpointStore() -> any AcuityPlanCheckpointStore {
        return MemoryAcuityPlanCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanCheckpointStore: AcuityPlanCheckpointStore {
        var inner: MemoryAcuityPlanCheckpointStore
        var cache: TTLCache<AcuityPlanCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanCheckpointStore, cache: TTLCache<AcuityPlanCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanCheckpoint? {
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

        func save(_ item: AcuityPlanCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanCheckpointStore(_ inner: MemoryAcuityPlanCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanCheckpointStore {
        return CachedAcuityPlanCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan checkpoints. Empty fields match all.
    final class AcuityPlanCheckpointQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanCheckpoint) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanCheckpoint]) -> [AcuityPlanCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanCheckpoints(_ store: any AcuityPlanCheckpointStore, query: AcuityPlanCheckpointQuery) -> [AcuityPlanCheckpoint] {
        return query.apply(store.list())
    }
}
