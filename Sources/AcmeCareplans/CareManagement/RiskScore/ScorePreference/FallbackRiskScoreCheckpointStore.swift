import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback risk score checkpoints by code.
    protocol FallbackRiskScoreCheckpointStore {
        func find(_ code: String) -> FallbackRiskScoreCheckpoint?
        func save(_ item: FallbackRiskScoreCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackRiskScoreCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackRiskScoreCheckpointStore: FallbackRiskScoreCheckpointStore {
        var items: [String: FallbackRiskScoreCheckpoint]
        var order: [String]

        init(items: [String: FallbackRiskScoreCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackRiskScoreCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackRiskScoreCheckpoint) {
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

        func list() -> [FallbackRiskScoreCheckpoint] {
            var out: [FallbackRiskScoreCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackRiskScoreCheckpointStore() -> any FallbackRiskScoreCheckpointStore {
        return MemoryFallbackRiskScoreCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackRiskScoreCheckpointStore: FallbackRiskScoreCheckpointStore {
        var inner: MemoryFallbackRiskScoreCheckpointStore
        var cache: TTLCache<FallbackRiskScoreCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackRiskScoreCheckpointStore, cache: TTLCache<FallbackRiskScoreCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackRiskScoreCheckpoint? {
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

        func save(_ item: FallbackRiskScoreCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackRiskScoreCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedFallbackRiskScoreCheckpointStore(_ inner: MemoryFallbackRiskScoreCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackRiskScoreCheckpointStore {
        return CachedFallbackRiskScoreCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback risk score checkpoints. Empty fields match all.
    final class FallbackRiskScoreCheckpointQuery {
        var channel: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackRiskScoreCheckpoint) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackRiskScoreCheckpoint]) -> [FallbackRiskScoreCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackRiskScoreCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackRiskScoreCheckpoints(_ store: any FallbackRiskScoreCheckpointStore, query: FallbackRiskScoreCheckpointQuery) -> [FallbackRiskScoreCheckpoint] {
        return query.apply(store.list())
    }
}
