import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback overtime checkpoints by code.
    protocol FallbackOvertimeCheckpointStore {
        func find(_ code: String) -> FallbackOvertimeCheckpoint?
        func save(_ item: FallbackOvertimeCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackOvertimeCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackOvertimeCheckpointStore: FallbackOvertimeCheckpointStore {
        var items: [String: FallbackOvertimeCheckpoint]
        var order: [String]

        init(items: [String: FallbackOvertimeCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackOvertimeCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackOvertimeCheckpoint) {
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

        func list() -> [FallbackOvertimeCheckpoint] {
            var out: [FallbackOvertimeCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackOvertimeCheckpointStore() -> any FallbackOvertimeCheckpointStore {
        return MemoryFallbackOvertimeCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackOvertimeCheckpointStore: FallbackOvertimeCheckpointStore {
        var inner: MemoryFallbackOvertimeCheckpointStore
        var cache: TTLCache<FallbackOvertimeCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackOvertimeCheckpointStore, cache: TTLCache<FallbackOvertimeCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackOvertimeCheckpoint? {
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

        func save(_ item: FallbackOvertimeCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackOvertimeCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedFallbackOvertimeCheckpointStore(_ inner: MemoryFallbackOvertimeCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackOvertimeCheckpointStore {
        return CachedFallbackOvertimeCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback overtime checkpoints. Empty fields match all.
    final class FallbackOvertimeCheckpointQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackOvertimeCheckpoint) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [FallbackOvertimeCheckpoint]) -> [FallbackOvertimeCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackOvertimeCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackOvertimeCheckpoints(_ store: any FallbackOvertimeCheckpointStore, query: FallbackOvertimeCheckpointQuery) -> [FallbackOvertimeCheckpoint] {
        return query.apply(store.list())
    }
}
