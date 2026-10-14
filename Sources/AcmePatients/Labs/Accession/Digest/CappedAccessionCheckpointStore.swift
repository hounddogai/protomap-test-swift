import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped accession checkpoints by code.
    protocol CappedAccessionCheckpointStore {
        func find(_ code: String) -> CappedAccessionCheckpoint?
        func save(_ item: CappedAccessionCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [CappedAccessionCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedAccessionCheckpointStore: CappedAccessionCheckpointStore {
        var items: [String: CappedAccessionCheckpoint]
        var order: [String]

        init(items: [String: CappedAccessionCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedAccessionCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedAccessionCheckpoint) {
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

        func list() -> [CappedAccessionCheckpoint] {
            var out: [CappedAccessionCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedAccessionCheckpointStore() -> any CappedAccessionCheckpointStore {
        return MemoryCappedAccessionCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedAccessionCheckpointStore: CappedAccessionCheckpointStore {
        var inner: MemoryCappedAccessionCheckpointStore
        var cache: TTLCache<CappedAccessionCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedAccessionCheckpointStore, cache: TTLCache<CappedAccessionCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedAccessionCheckpoint? {
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

        func save(_ item: CappedAccessionCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedAccessionCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedCappedAccessionCheckpointStore(_ inner: MemoryCappedAccessionCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedAccessionCheckpointStore {
        return CachedCappedAccessionCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped accession checkpoints. Empty fields match all.
    final class CappedAccessionCheckpointQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedAccessionCheckpoint) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [CappedAccessionCheckpoint]) -> [CappedAccessionCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedAccessionCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedAccessionCheckpoints(_ store: any CappedAccessionCheckpointStore, query: CappedAccessionCheckpointQuery) -> [CappedAccessionCheckpoint] {
        return query.apply(store.list())
    }
}
