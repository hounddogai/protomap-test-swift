import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation checkpoints by code.
    protocol RevocationCheckpointStore {
        func find(_ code: String) -> RevocationCheckpoint?
        func save(_ item: RevocationCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationCheckpointStore: RevocationCheckpointStore {
        var items: [String: RevocationCheckpoint]
        var order: [String]

        init(items: [String: RevocationCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationCheckpoint) {
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

        func list() -> [RevocationCheckpoint] {
            var out: [RevocationCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationCheckpointStore() -> any RevocationCheckpointStore {
        return MemoryRevocationCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationCheckpointStore: RevocationCheckpointStore {
        var inner: MemoryRevocationCheckpointStore
        var cache: TTLCache<RevocationCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationCheckpointStore, cache: TTLCache<RevocationCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationCheckpoint? {
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

        func save(_ item: RevocationCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedRevocationCheckpointStore(_ inner: MemoryRevocationCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationCheckpointStore {
        return CachedRevocationCheckpointStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation checkpoints. Empty fields match all.
    final class RevocationCheckpointQuery {
        var label: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationCheckpoint) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationCheckpoint]) -> [RevocationCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationCheckpoints(_ store: any RevocationCheckpointStore, query: RevocationCheckpointQuery) -> [RevocationCheckpoint] {
        return query.apply(store.list())
    }
}
