import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization checkpoints by code.
    protocol AuthorizationCheckpointStore {
        func find(_ code: String) -> AuthorizationCheckpoint?
        func save(_ item: AuthorizationCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationCheckpointStore: AuthorizationCheckpointStore {
        var items: [String: AuthorizationCheckpoint]
        var order: [String]

        init(items: [String: AuthorizationCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationCheckpoint) {
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

        func list() -> [AuthorizationCheckpoint] {
            var out: [AuthorizationCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationCheckpointStore() -> any AuthorizationCheckpointStore {
        return MemoryAuthorizationCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationCheckpointStore: AuthorizationCheckpointStore {
        var inner: MemoryAuthorizationCheckpointStore
        var cache: TTLCache<AuthorizationCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationCheckpointStore, cache: TTLCache<AuthorizationCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationCheckpoint? {
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

        func save(_ item: AuthorizationCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationCheckpointStore(_ inner: MemoryAuthorizationCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationCheckpointStore {
        return CachedAuthorizationCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization checkpoints. Empty fields match all.
    final class AuthorizationCheckpointQuery {
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

        func matches(_ item: AuthorizationCheckpoint) -> Bool {
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

        func apply(_ items: [AuthorizationCheckpoint]) -> [AuthorizationCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationCheckpoints(_ store: any AuthorizationCheckpointStore, query: AuthorizationCheckpointQuery) -> [AuthorizationCheckpoint] {
        return query.apply(store.list())
    }
}
