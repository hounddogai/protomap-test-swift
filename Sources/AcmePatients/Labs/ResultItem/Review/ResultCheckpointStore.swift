import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result checkpoints by code.
    protocol ResultCheckpointStore {
        func find(_ code: String) -> ResultCheckpoint?
        func save(_ item: ResultCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [ResultCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultCheckpointStore: ResultCheckpointStore {
        var items: [String: ResultCheckpoint]
        var order: [String]

        init(items: [String: ResultCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultCheckpoint) {
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

        func list() -> [ResultCheckpoint] {
            var out: [ResultCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultCheckpointStore() -> any ResultCheckpointStore {
        return MemoryResultCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultCheckpointStore: ResultCheckpointStore {
        var inner: MemoryResultCheckpointStore
        var cache: TTLCache<ResultCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultCheckpointStore, cache: TTLCache<ResultCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultCheckpoint? {
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

        func save(_ item: ResultCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedResultCheckpointStore(_ inner: MemoryResultCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultCheckpointStore {
        return CachedResultCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result checkpoints. Empty fields match all.
    final class ResultCheckpointQuery {
        var source: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minAmount: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultCheckpoint) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultCheckpoint]) -> [ResultCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultCheckpoints(_ store: any ResultCheckpointStore, query: ResultCheckpointQuery) -> [ResultCheckpoint] {
        return query.apply(store.list())
    }
}
