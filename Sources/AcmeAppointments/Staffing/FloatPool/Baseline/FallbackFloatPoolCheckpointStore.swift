import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback float pool checkpoints by code.
    protocol FallbackFloatPoolCheckpointStore {
        func find(_ code: String) -> FallbackFloatPoolCheckpoint?
        func save(_ item: FallbackFloatPoolCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackFloatPoolCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackFloatPoolCheckpointStore: FallbackFloatPoolCheckpointStore {
        var items: [String: FallbackFloatPoolCheckpoint]
        var order: [String]

        init(items: [String: FallbackFloatPoolCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackFloatPoolCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackFloatPoolCheckpoint) {
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

        func list() -> [FallbackFloatPoolCheckpoint] {
            var out: [FallbackFloatPoolCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackFloatPoolCheckpointStore() -> any FallbackFloatPoolCheckpointStore {
        return MemoryFallbackFloatPoolCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackFloatPoolCheckpointStore: FallbackFloatPoolCheckpointStore {
        var inner: MemoryFallbackFloatPoolCheckpointStore
        var cache: TTLCache<FallbackFloatPoolCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackFloatPoolCheckpointStore, cache: TTLCache<FallbackFloatPoolCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackFloatPoolCheckpoint? {
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

        func save(_ item: FallbackFloatPoolCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackFloatPoolCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedFallbackFloatPoolCheckpointStore(_ inner: MemoryFallbackFloatPoolCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackFloatPoolCheckpointStore {
        return CachedFallbackFloatPoolCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback float pool checkpoints. Empty fields match all.
    final class FallbackFloatPoolCheckpointQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackFloatPoolCheckpoint) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackFloatPoolCheckpoint]) -> [FallbackFloatPoolCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackFloatPoolCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackFloatPoolCheckpoints(_ store: any FallbackFloatPoolCheckpointStore, query: FallbackFloatPoolCheckpointQuery) -> [FallbackFloatPoolCheckpoint] {
        return query.apply(store.list())
    }
}
