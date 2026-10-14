import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps rolling authorization checkpoints by code.
    protocol RollingAuthorizationCheckpointStore {
        func find(_ code: String) -> RollingAuthorizationCheckpoint?
        func save(_ item: RollingAuthorizationCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAuthorizationCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAuthorizationCheckpointStore: RollingAuthorizationCheckpointStore {
        var items: [String: RollingAuthorizationCheckpoint]
        var order: [String]

        init(items: [String: RollingAuthorizationCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAuthorizationCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAuthorizationCheckpoint) {
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

        func list() -> [RollingAuthorizationCheckpoint] {
            var out: [RollingAuthorizationCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAuthorizationCheckpointStore() -> any RollingAuthorizationCheckpointStore {
        return MemoryRollingAuthorizationCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAuthorizationCheckpointStore: RollingAuthorizationCheckpointStore {
        var inner: MemoryRollingAuthorizationCheckpointStore
        var cache: TTLCache<RollingAuthorizationCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAuthorizationCheckpointStore, cache: TTLCache<RollingAuthorizationCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAuthorizationCheckpoint? {
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

        func save(_ item: RollingAuthorizationCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAuthorizationCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedRollingAuthorizationCheckpointStore(_ inner: MemoryRollingAuthorizationCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAuthorizationCheckpointStore {
        return CachedRollingAuthorizationCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling authorization checkpoints. Empty fields match all.
    final class RollingAuthorizationCheckpointQuery {
        var category: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingAuthorizationCheckpoint) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingAuthorizationCheckpoint]) -> [RollingAuthorizationCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAuthorizationCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAuthorizationCheckpoints(_ store: any RollingAuthorizationCheckpointStore, query: RollingAuthorizationCheckpointQuery) -> [RollingAuthorizationCheckpoint] {
        return query.apply(store.list())
    }
}
