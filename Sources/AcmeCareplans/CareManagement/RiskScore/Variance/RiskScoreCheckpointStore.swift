import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score checkpoints by code.
    protocol RiskScoreCheckpointStore {
        func find(_ code: String) -> RiskScoreCheckpoint?
        func save(_ item: RiskScoreCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreCheckpointStore: RiskScoreCheckpointStore {
        var items: [String: RiskScoreCheckpoint]
        var order: [String]

        init(items: [String: RiskScoreCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreCheckpoint) {
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

        func list() -> [RiskScoreCheckpoint] {
            var out: [RiskScoreCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreCheckpointStore() -> any RiskScoreCheckpointStore {
        return MemoryRiskScoreCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreCheckpointStore: RiskScoreCheckpointStore {
        var inner: MemoryRiskScoreCheckpointStore
        var cache: TTLCache<RiskScoreCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreCheckpointStore, cache: TTLCache<RiskScoreCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreCheckpoint? {
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

        func save(_ item: RiskScoreCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreCheckpointStore(_ inner: MemoryRiskScoreCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreCheckpointStore {
        return CachedRiskScoreCheckpointStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score checkpoints. Empty fields match all.
    final class RiskScoreCheckpointQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreCheckpoint) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreCheckpoint]) -> [RiskScoreCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreCheckpoints(_ store: any RiskScoreCheckpointStore, query: RiskScoreCheckpointQuery) -> [RiskScoreCheckpoint] {
        return query.apply(store.list())
    }
}
