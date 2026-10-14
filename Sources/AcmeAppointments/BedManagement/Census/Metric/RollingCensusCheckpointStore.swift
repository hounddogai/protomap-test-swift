import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps rolling census checkpoints by code.
    protocol RollingCensusCheckpointStore {
        func find(_ code: String) -> RollingCensusCheckpoint?
        func save(_ item: RollingCensusCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [RollingCensusCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingCensusCheckpointStore: RollingCensusCheckpointStore {
        var items: [String: RollingCensusCheckpoint]
        var order: [String]

        init(items: [String: RollingCensusCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingCensusCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingCensusCheckpoint) {
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

        func list() -> [RollingCensusCheckpoint] {
            var out: [RollingCensusCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingCensusCheckpointStore() -> any RollingCensusCheckpointStore {
        return MemoryRollingCensusCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingCensusCheckpointStore: RollingCensusCheckpointStore {
        var inner: MemoryRollingCensusCheckpointStore
        var cache: TTLCache<RollingCensusCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingCensusCheckpointStore, cache: TTLCache<RollingCensusCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingCensusCheckpoint? {
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

        func save(_ item: RollingCensusCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingCensusCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedRollingCensusCheckpointStore(_ inner: MemoryRollingCensusCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingCensusCheckpointStore {
        return CachedRollingCensusCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling census checkpoints. Empty fields match all.
    final class RollingCensusCheckpointQuery {
        var locale: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRetries: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingCensusCheckpoint) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [RollingCensusCheckpoint]) -> [RollingCensusCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingCensusCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingCensusCheckpoints(_ store: any RollingCensusCheckpointStore, query: RollingCensusCheckpointQuery) -> [RollingCensusCheckpoint] {
        return query.apply(store.list())
    }
}
