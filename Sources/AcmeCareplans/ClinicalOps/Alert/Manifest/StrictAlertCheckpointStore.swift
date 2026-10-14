import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict alert checkpoints by code.
    protocol StrictAlertCheckpointStore {
        func find(_ code: String) -> StrictAlertCheckpoint?
        func save(_ item: StrictAlertCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [StrictAlertCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictAlertCheckpointStore: StrictAlertCheckpointStore {
        var items: [String: StrictAlertCheckpoint]
        var order: [String]

        init(items: [String: StrictAlertCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictAlertCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictAlertCheckpoint) {
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

        func list() -> [StrictAlertCheckpoint] {
            var out: [StrictAlertCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictAlertCheckpointStore() -> any StrictAlertCheckpointStore {
        return MemoryStrictAlertCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictAlertCheckpointStore: StrictAlertCheckpointStore {
        var inner: MemoryStrictAlertCheckpointStore
        var cache: TTLCache<StrictAlertCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictAlertCheckpointStore, cache: TTLCache<StrictAlertCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictAlertCheckpoint? {
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

        func save(_ item: StrictAlertCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictAlertCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedStrictAlertCheckpointStore(_ inner: MemoryStrictAlertCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictAlertCheckpointStore {
        return CachedStrictAlertCheckpointStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict alert checkpoints. Empty fields match all.
    final class StrictAlertCheckpointQuery {
        var ward: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minScore: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictAlertCheckpoint) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [StrictAlertCheckpoint]) -> [StrictAlertCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictAlertCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictAlertCheckpoints(_ store: any StrictAlertCheckpointStore, query: StrictAlertCheckpointQuery) -> [StrictAlertCheckpoint] {
        return query.apply(store.list())
    }
}
