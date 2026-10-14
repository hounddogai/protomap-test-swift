import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential checkpoints by code.
    protocol CredentialCheckpointStore {
        func find(_ code: String) -> CredentialCheckpoint?
        func save(_ item: CredentialCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialCheckpointStore: CredentialCheckpointStore {
        var items: [String: CredentialCheckpoint]
        var order: [String]

        init(items: [String: CredentialCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialCheckpoint) {
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

        func list() -> [CredentialCheckpoint] {
            var out: [CredentialCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialCheckpointStore() -> any CredentialCheckpointStore {
        return MemoryCredentialCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialCheckpointStore: CredentialCheckpointStore {
        var inner: MemoryCredentialCheckpointStore
        var cache: TTLCache<CredentialCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialCheckpointStore, cache: TTLCache<CredentialCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialCheckpoint? {
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

        func save(_ item: CredentialCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedCredentialCheckpointStore(_ inner: MemoryCredentialCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialCheckpointStore {
        return CachedCredentialCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential checkpoints. Empty fields match all.
    final class CredentialCheckpointQuery {
        var region: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minLimit: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialCheckpoint) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialCheckpoint]) -> [CredentialCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialCheckpoints(_ store: any CredentialCheckpointStore, query: CredentialCheckpointQuery) -> [CredentialCheckpoint] {
        return query.apply(store.list())
    }
}
