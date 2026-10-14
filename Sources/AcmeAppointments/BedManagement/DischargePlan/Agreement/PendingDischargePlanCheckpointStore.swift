import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps pending discharge plan checkpoints by code.
    protocol PendingDischargePlanCheckpointStore {
        func find(_ code: String) -> PendingDischargePlanCheckpoint?
        func save(_ item: PendingDischargePlanCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [PendingDischargePlanCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingDischargePlanCheckpointStore: PendingDischargePlanCheckpointStore {
        var items: [String: PendingDischargePlanCheckpoint]
        var order: [String]

        init(items: [String: PendingDischargePlanCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingDischargePlanCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingDischargePlanCheckpoint) {
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

        func list() -> [PendingDischargePlanCheckpoint] {
            var out: [PendingDischargePlanCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingDischargePlanCheckpointStore() -> any PendingDischargePlanCheckpointStore {
        return MemoryPendingDischargePlanCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingDischargePlanCheckpointStore: PendingDischargePlanCheckpointStore {
        var inner: MemoryPendingDischargePlanCheckpointStore
        var cache: TTLCache<PendingDischargePlanCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingDischargePlanCheckpointStore, cache: TTLCache<PendingDischargePlanCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingDischargePlanCheckpoint? {
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

        func save(_ item: PendingDischargePlanCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingDischargePlanCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedPendingDischargePlanCheckpointStore(_ inner: MemoryPendingDischargePlanCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingDischargePlanCheckpointStore {
        return CachedPendingDischargePlanCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending discharge plan checkpoints. Empty fields match all.
    final class PendingDischargePlanCheckpointQuery {
        var unit: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingDischargePlanCheckpoint) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingDischargePlanCheckpoint]) -> [PendingDischargePlanCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingDischargePlanCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingDischargePlanCheckpoints(_ store: any PendingDischargePlanCheckpointStore, query: PendingDischargePlanCheckpointQuery) -> [PendingDischargePlanCheckpoint] {
        return query.apply(store.list())
    }
}
