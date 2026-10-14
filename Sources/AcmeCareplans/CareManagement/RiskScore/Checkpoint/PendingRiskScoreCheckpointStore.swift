import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending risk score checkpoints by code.
    protocol PendingRiskScoreCheckpointStore {
        func find(_ code: String) -> PendingRiskScoreCheckpoint?
        func save(_ item: PendingRiskScoreCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRiskScoreCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRiskScoreCheckpointStore: PendingRiskScoreCheckpointStore {
        var items: [String: PendingRiskScoreCheckpoint]
        var order: [String]

        init(items: [String: PendingRiskScoreCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRiskScoreCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRiskScoreCheckpoint) {
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

        func list() -> [PendingRiskScoreCheckpoint] {
            var out: [PendingRiskScoreCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRiskScoreCheckpointStore() -> any PendingRiskScoreCheckpointStore {
        return MemoryPendingRiskScoreCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRiskScoreCheckpointStore: PendingRiskScoreCheckpointStore {
        var inner: MemoryPendingRiskScoreCheckpointStore
        var cache: TTLCache<PendingRiskScoreCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRiskScoreCheckpointStore, cache: TTLCache<PendingRiskScoreCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRiskScoreCheckpoint? {
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

        func save(_ item: PendingRiskScoreCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRiskScoreCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedPendingRiskScoreCheckpointStore(_ inner: MemoryPendingRiskScoreCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRiskScoreCheckpointStore {
        return CachedPendingRiskScoreCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending risk score checkpoints. Empty fields match all.
    final class PendingRiskScoreCheckpointQuery {
        var segment: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minBudget: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRiskScoreCheckpoint) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingRiskScoreCheckpoint]) -> [PendingRiskScoreCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRiskScoreCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRiskScoreCheckpoints(_ store: any PendingRiskScoreCheckpointStore, query: PendingRiskScoreCheckpointQuery) -> [PendingRiskScoreCheckpoint] {
        return query.apply(store.list())
    }
}
