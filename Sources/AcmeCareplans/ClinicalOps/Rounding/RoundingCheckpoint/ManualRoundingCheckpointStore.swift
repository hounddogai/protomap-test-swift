import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps manual rounding checkpoints by code.
    protocol ManualRoundingCheckpointStore {
        func find(_ code: String) -> ManualRoundingCheckpoint?
        func save(_ item: ManualRoundingCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRoundingCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRoundingCheckpointStore: ManualRoundingCheckpointStore {
        var items: [String: ManualRoundingCheckpoint]
        var order: [String]

        init(items: [String: ManualRoundingCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRoundingCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRoundingCheckpoint) {
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

        func list() -> [ManualRoundingCheckpoint] {
            var out: [ManualRoundingCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRoundingCheckpointStore() -> any ManualRoundingCheckpointStore {
        return MemoryManualRoundingCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRoundingCheckpointStore: ManualRoundingCheckpointStore {
        var inner: MemoryManualRoundingCheckpointStore
        var cache: TTLCache<ManualRoundingCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRoundingCheckpointStore, cache: TTLCache<ManualRoundingCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRoundingCheckpoint? {
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

        func save(_ item: ManualRoundingCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRoundingCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedManualRoundingCheckpointStore(_ inner: MemoryManualRoundingCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRoundingCheckpointStore {
        return CachedManualRoundingCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual rounding checkpoints. Empty fields match all.
    final class ManualRoundingCheckpointQuery {
        var title: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRetries: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRoundingCheckpoint) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualRoundingCheckpoint]) -> [ManualRoundingCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRoundingCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRoundingCheckpoints(_ store: any ManualRoundingCheckpointStore, query: ManualRoundingCheckpointQuery) -> [ManualRoundingCheckpoint] {
        return query.apply(store.list())
    }
}
