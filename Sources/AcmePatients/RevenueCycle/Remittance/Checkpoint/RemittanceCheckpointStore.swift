import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance checkpoints by code.
    protocol RemittanceCheckpointStore {
        func find(_ code: String) -> RemittanceCheckpoint?
        func save(_ item: RemittanceCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceCheckpointStore: RemittanceCheckpointStore {
        var items: [String: RemittanceCheckpoint]
        var order: [String]

        init(items: [String: RemittanceCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceCheckpoint) {
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

        func list() -> [RemittanceCheckpoint] {
            var out: [RemittanceCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceCheckpointStore() -> any RemittanceCheckpointStore {
        return MemoryRemittanceCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceCheckpointStore: RemittanceCheckpointStore {
        var inner: MemoryRemittanceCheckpointStore
        var cache: TTLCache<RemittanceCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceCheckpointStore, cache: TTLCache<RemittanceCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceCheckpoint? {
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

        func save(_ item: RemittanceCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedRemittanceCheckpointStore(_ inner: MemoryRemittanceCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceCheckpointStore {
        return CachedRemittanceCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance checkpoints. Empty fields match all.
    final class RemittanceCheckpointQuery {
        var category: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceCheckpoint) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [RemittanceCheckpoint]) -> [RemittanceCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceCheckpoints(_ store: any RemittanceCheckpointStore, query: RemittanceCheckpointQuery) -> [RemittanceCheckpoint] {
        return query.apply(store.list())
    }
}
