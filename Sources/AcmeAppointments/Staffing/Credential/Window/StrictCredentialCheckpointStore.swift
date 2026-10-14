import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict credential checkpoints by code.
    protocol StrictCredentialCheckpointStore {
        func find(_ code: String) -> StrictCredentialCheckpoint?
        func save(_ item: StrictCredentialCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [StrictCredentialCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictCredentialCheckpointStore: StrictCredentialCheckpointStore {
        var items: [String: StrictCredentialCheckpoint]
        var order: [String]

        init(items: [String: StrictCredentialCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictCredentialCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictCredentialCheckpoint) {
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

        func list() -> [StrictCredentialCheckpoint] {
            var out: [StrictCredentialCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictCredentialCheckpointStore() -> any StrictCredentialCheckpointStore {
        return MemoryStrictCredentialCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictCredentialCheckpointStore: StrictCredentialCheckpointStore {
        var inner: MemoryStrictCredentialCheckpointStore
        var cache: TTLCache<StrictCredentialCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictCredentialCheckpointStore, cache: TTLCache<StrictCredentialCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictCredentialCheckpoint? {
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

        func save(_ item: StrictCredentialCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictCredentialCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedStrictCredentialCheckpointStore(_ inner: MemoryStrictCredentialCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictCredentialCheckpointStore {
        return CachedStrictCredentialCheckpointStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict credential checkpoints. Empty fields match all.
    final class StrictCredentialCheckpointQuery {
        var ward: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictCredentialCheckpoint) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictCredentialCheckpoint]) -> [StrictCredentialCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictCredentialCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictCredentialCheckpoints(_ store: any StrictCredentialCheckpointStore, query: StrictCredentialCheckpointQuery) -> [StrictCredentialCheckpoint] {
        return query.apply(store.list())
    }
}
